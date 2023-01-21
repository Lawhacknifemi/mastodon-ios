// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Foundation
import MastodonSDK
import CoreDataStack

extension APIService {
    public func getHistory(
    forStatusID statusID: Status.ID,
    authenticationBox: MastodonAuthenticationBox) async throws -> Mastodon.Response.Content<[Mastodon.Entity.StatusEdit]> {
        let domain = authenticationBox.domain
        let authorization = authenticationBox.userAuthorization

        let response = try await Mastodon.API.Statuses.editHistory(
            forStatusID: statusID,
            session: session,
            domain: domain,
            authorization: authorization).singleOutput()

        guard response.value.isEmpty == false else { return response }

        let managedObjectContext = self.backgroundManagedObjectContext

        try await managedObjectContext.performChanges {
            // get status
            guard let status = Status.fetch(in: managedObjectContext, configurationBlock: {
                $0.predicate = Status.predicate(domain: domain, id: statusID)
            }).first else { return }

            Persistence.StatusEdit.createOrMerge(in: managedObjectContext,
                                                 statusEdits: response.value,
                                                 forStatus: status)
        }

        return response
    }
}
