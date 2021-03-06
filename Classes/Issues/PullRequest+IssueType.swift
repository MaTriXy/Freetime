//
//  PullRequest+IssueType.swift
//  Freetime
//
//  Created by Ryan Nystrom on 6/4/17.
//  Copyright © 2017 Ryan Nystrom. All rights reserved.
//

import Foundation
import IGListKit

extension IssueOrPullRequestQuery.Data.Repository.IssueOrPullRequest.AsPullRequest: IssueType {

    var id: String {
        return fragments.nodeFields.id
    }

    var pullRequest: Bool {
        return true
    }

    var labelableFields: LabelableFields {
        return fragments.labelableFields
    }

    var commentFields: CommentFields {
        return fragments.commentFields
    }

    var reactionFields: ReactionFields {
        return fragments.reactionFields
    }

    var closableFields: ClosableFields {
        return fragments.closableFields
    }

    var locked: Bool {
        return fragments.lockableFields.locked
    }

    func timelineViewModels(width: CGFloat) -> [ListDiffable] {
        var results = [ListDiffable]()

        for node in timeline.nodes ?? [] {
            guard let node = node else { continue }

            if let comment = node.asIssueComment {
                if let model = createCommentModel(
                    id: comment.fragments.nodeFields.id,
                    commentFields: comment.fragments.commentFields,
                    reactionFields: comment.fragments.reactionFields,
                    width: width,
                    threadState: .single
                    ) {
                    results.append(model)
                }
            } else if let unlabeled = node.asUnlabeledEvent,
                let date = GithubAPIDateFormatter().date(from: unlabeled.createdAt) {
                let model = IssueLabeledModel(
                    id: unlabeled.fragments.nodeFields.id,
                    actor: unlabeled.actor?.login ?? Strings.unknown,
                    title: unlabeled.label.name,
                    color: unlabeled.label.color,
                    date: date,
                    type: .removed
                )
                results.append(model)
            } else if let labeled = node.asLabeledEvent,
                let date = GithubAPIDateFormatter().date(from: labeled.createdAt) {
                let model = IssueLabeledModel(
                    id: labeled.fragments.nodeFields.id,
                    actor: labeled.actor?.login ?? Strings.unknown,
                    title: labeled.label.name,
                    color: labeled.label.color,
                    date: date,
                    type: .added
                )
                results.append(model)
            } else if let closed = node.asClosedEvent,
                let date = GithubAPIDateFormatter().date(from: closed.createdAt) {
                let model = IssueStatusEventModel(
                    id: closed.fragments.nodeFields.id,
                    actor: closed.actor?.login ?? Strings.unknown,
                    date: date,
                    status: .closed,
                    pullRequest: true
                )
                results.append(model)
            } else if let reopened = node.asReopenedEvent,
                let date = GithubAPIDateFormatter().date(from: reopened.createdAt) {
                let model = IssueStatusEventModel(
                    id: reopened.fragments.nodeFields.id,
                    actor: reopened.actor?.login ?? Strings.unknown,
                    date: date,
                    status: .reopened,
                    pullRequest: true
                )
                results.append(model)
            } else if let merged = node.asMergedEvent,
                let date = GithubAPIDateFormatter().date(from: merged.createdAt) {
                let model = IssueMergedModel(
                    date: date,
                    commitHash: merged.commit.oid,
                    actor: merged.actor?.login ?? Strings.unknown
                )
                results.append(model)
            } else if let locked = node.asLockedEvent,
                let date = GithubAPIDateFormatter().date(from: locked.createdAt) {
                let model = IssueStatusEventModel(
                    id: locked.fragments.nodeFields.id,
                    actor: locked.actor?.login ?? Strings.unknown,
                    date: date,
                    status: .locked,
                    pullRequest: false
                )
                results.append(model)
            } else if let unlocked = node.asUnlockedEvent,
                let date = GithubAPIDateFormatter().date(from: unlocked.createdAt) {
                let model = IssueStatusEventModel(
                    id: unlocked.fragments.nodeFields.id,
                    actor: unlocked.actor?.login ?? Strings.unknown,
                    date: date,
                    status: .unlocked,
                    pullRequest: false
                )
                results.append(model)
            } else if let thread = node.asPullRequestReviewThread,
                let hunk = diffHunkModel(thread: thread) {
                // add the diff hunk FIRST then the threaded comments so that the section controllers end up stacked
                // on top of each other
                results.append(hunk)
                results += commentModels(thread: thread, width: width)
            }
        }

        return results
    }

    private func diffHunkCodePreview(code: String) -> NSAttributedString {
        let split = code.components(separatedBy: CharacterSet.newlines)
        let count = split.count
        let cutLines = min(count, 4)
        let lastLines = split[(count-cutLines)..<count]

        let attributedString = NSMutableAttributedString()

        for line in lastLines {
            var attributes = [
                NSFontAttributeName: Styles.Fonts.code,
                NSForegroundColorAttributeName: Styles.Colors.Gray.dark.color
            ]
            if line.hasPrefix("+") {
                attributes[NSBackgroundColorAttributeName] = Styles.Colors.Green.light.color
            } else if line.hasPrefix("-") {
                attributes[NSBackgroundColorAttributeName] = Styles.Colors.Red.light.color
            }

            let newlinedLine = line != lastLines.last ? line + "\n" : line
            attributedString.append(NSAttributedString(string: newlinedLine, attributes: attributes))
        }

        return attributedString
    }

    private func diffHunkModel(thread: Timeline.Node.AsPullRequestReviewThread) -> ListDiffable? {
        guard let node = thread.comments.nodes?.first, let firstComment = node else { return nil }
        let code = diffHunkCodePreview(code: firstComment.diffHunk)
        let text = NSAttributedStringSizing(containerWidth: 0, attributedText: code, inset: IssueDiffHunkPreviewCell.textViewInset)
        return IssueDiffHunkModel(path: firstComment.path, preview: text)
    }

    private func commentModels(thread: Timeline.Node.AsPullRequestReviewThread, width: CGFloat) -> [ListDiffable] {
        var results = [ListDiffable]()

        let headNodeId = thread.comments.nodes?.first??.fragments.nodeFields.id
        let tailNodeId = thread.comments.nodes?.last??.fragments.nodeFields.id

        for node in thread.comments.nodes ?? [] {
            guard let fragments = node?.fragments else { continue }

            let id = fragments.nodeFields.id
            let isHead = id == headNodeId
            let isTail = id == tailNodeId

            if let model = createCommentModel(
                id: fragments.nodeFields.id,
                commentFields: fragments.commentFields,
                reactionFields: fragments.reactionFields,
                width: width,
                threadState: isHead ? .head : isTail ? .tail : .neck
                ) {
                results.append(model)
            }
        }
        return results
    }

}
