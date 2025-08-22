
import Testing
@testable import Bragit
import Dependencies
import ReactorKit

struct BragitTests {

  @Test func HomeReactorTest() async throws {
    let reactor: HomeReactor = HomeReactor()

    reactor.action.onNext(.loadNextPosts)
    #expect(reactor.currentState.posts.count != 0)

    reactor.action.onNext(.loadPosts)
    #expect(reactor.currentState.posts.count != 0)
  }
}
