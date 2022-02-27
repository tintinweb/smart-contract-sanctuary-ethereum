/**
 *Submitted for verification at Etherscan.io on 2022-02-27
*/

library StringUtils {
    function equals(string memory a, string memory b)
        internal
        pure
        returns (bool)
    {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    function notEquals(string memory a, string memory b)
        internal
        pure
        returns (bool)
    {
        return !equals(a, b);
    }

    function empty(string memory a)
        internal
        pure
        returns (bool)
    {
        return equals(a, "");
    }

    function notEmpty(string memory a)
        internal
        pure
        returns (bool)
    {
        return !empty(a);
    }
}

// LibCLL using `string` keys
library LibCLLs {
    using StringUtils for string;

    bytes32 public constant VERSION = "LibCLLs 0.4.1";
    string constant NULL = "0";
    string constant HEAD = "0";
    bool constant PREV = false;
    bool constant NEXT = true;

    struct CLL {
        mapping(string => mapping(bool => string)) cll;
    }

    // n: node id  d: direction  r: return node id

    // Return existential state of a list.
    function exists(CLL storage self) internal view returns (bool) {
        return
            self.cll[HEAD][PREV].notEquals(HEAD) ||
            self.cll[HEAD][NEXT].notEquals(HEAD);
    }

    // Returns the number of elements in the list
    function sizeOf(CLL storage self) internal view returns (uint256) {
        uint256 r = 0;
        string memory i = step(self, HEAD, NEXT);
        while (i.notEquals(HEAD)) {
            i = step(self, i, NEXT);
            r++;
        }
        return r;
    }

    // Returns the links of a node as and array
    function getNode(CLL storage self, string memory n)
        internal
        view
        returns (string[2] memory)
    {
        return [self.cll[n][PREV], self.cll[n][NEXT]];
    }

    // Returns the link of a node `n` in direction `d`.
    function step(
        CLL storage self,
        string memory n,
        bool d
    ) internal view returns (string memory) {
        return self.cll[n][d];
    }

    // Creates a bidirectional link between two nodes on direction `d`
    function stitch(
        CLL storage self,
        string memory a,
        string memory b,
        bool d
    ) internal {
        self.cll[b][!d] = a;
        self.cll[a][d] = b;
    }

    // Insert node `b` beside existing node `a` in direction `d`.
    function insert(
        CLL storage self,
        string memory a,
        string memory b,
        bool d
    ) internal {
        string memory c = self.cll[a][d];
        stitch(self, a, b, d);
        stitch(self, b, c, d);
    }

    // Remove node
    function remove(CLL storage self, string memory n)
        internal
        returns (string memory)
    {
        if (n.equals(NULL)) return n;
        stitch(self, self.cll[n][PREV], self.cll[n][NEXT], NEXT);
        delete self.cll[n][PREV];
        delete self.cll[n][NEXT];
        return n;
    }

    // Push a new node before or after the head
    function push(
        CLL storage self,
        string memory n,
        bool d
    ) public {
        insert(self, HEAD, n, d);
    }

    // Pop a new node from before or after the head
    function pop(CLL storage self, bool d) internal returns (string memory) {
        return remove(self, step(self, HEAD, d));
    }
}