import Foundation

struct ClaimedPathIndex {
    private final class Node {
        var claimedPath: String?
        var children: [String: Node] = [:]
    }

    private let root = Node()

    func insert(_ path: String) -> Bool {
        var node = root
        for component in components(of: path) {
            if node.claimedPath != nil {
                return false
            }
            if let child = node.children[component] {
                node = child
            } else {
                let child = Node()
                node.children[component] = child
                node = child
            }
        }

        guard node.claimedPath == nil else { return false }
        node.claimedPath = path
        node.children.removeAll(keepingCapacity: false)
        return true
    }

    func exclusionsIfUnclaimed(for path: String) -> Set<String>? {
        var node = root
        if node.claimedPath != nil {
            return nil
        }

        for component in components(of: path) {
            guard let child = node.children[component] else {
                return []
            }
            node = child
            if node.claimedPath != nil {
                return nil
            }
        }

        var paths: Set<String> = []
        for child in node.children.values {
            collectClaimedPaths(from: child, into: &paths)
        }
        return paths
    }

    private func collectClaimedPaths(
        from node: Node,
        into paths: inout Set<String>
    ) {
        if let claimedPath = node.claimedPath {
            paths.insert(claimedPath)
            return
        }
        for child in node.children.values {
            collectClaimedPaths(from: child, into: &paths)
        }
    }

    private func components(of path: String) -> [String] {
        path.split(separator: "/", omittingEmptySubsequences: true).map(String.init)
    }
}

struct ChangedPathIndex {
    private final class Node {
        var isChanged = false
        var containsChange = false
        var children: [String: Node] = [:]
    }

    private let root = Node()

    init(paths: Set<String>) {
        for path in paths {
            insert(path)
        }
    }

    func overlaps(_ path: String) -> Bool {
        var node = root
        if node.isChanged { return true }

        for component in components(of: path) {
            guard let child = node.children[component] else {
                return false
            }
            node = child
            if node.isChanged {
                return true
            }
        }

        return node.containsChange
    }

    private func insert(_ path: String) {
        var node = root
        node.containsChange = true

        for component in components(of: path) {
            if let child = node.children[component] {
                node = child
            } else {
                let child = Node()
                node.children[component] = child
                node = child
            }
            node.containsChange = true
        }
        node.isChanged = true
    }

    private func components(of path: String) -> [String] {
        path.split(separator: "/", omittingEmptySubsequences: true).map(String.init)
    }
}
