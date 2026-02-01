import Foundation
@testable import SkylightApp

final class MockFamilyService: FamilyServiceProtocol {
    var familyMembersToReturn: [FamilyMember] = []
    var devicesToReturn: [Device] = []
    var errorToThrow: Error?

    var getFamilyMembersCalled = false
    var getDevicesCalled = false
    var lastFrameId: String?

    func getFamilyMembers(frameId: String) async throws -> [FamilyMember] {
        getFamilyMembersCalled = true
        lastFrameId = frameId

        if let error = errorToThrow {
            throw error
        }
        return familyMembersToReturn
    }

    func getDevices(frameId: String) async throws -> [Device] {
        getDevicesCalled = true
        lastFrameId = frameId

        if let error = errorToThrow {
            throw error
        }
        return devicesToReturn
    }

    func reset() {
        familyMembersToReturn = []
        devicesToReturn = []
        errorToThrow = nil
        getFamilyMembersCalled = false
        getDevicesCalled = false
        lastFrameId = nil
    }
}
