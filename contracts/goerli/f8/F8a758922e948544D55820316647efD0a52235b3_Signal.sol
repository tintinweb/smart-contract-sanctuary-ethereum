// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC721} from "./ERC721.sol";
import {Base64} from "./Base64.sol";
import {ReentrancyGuard} from "./ReentrancyGuard.sol";

contract Signal is ERC721, ReentrancyGuard {
    uint256 public constant BRAVO = 1;
    uint256 public constant KILO = 2;
    uint256 public constant LIMA = 3;
    uint256 public constant CHARLIE = 4;
    uint256 public constant BLACK_SPOT = 5;
    uint256 public constant AFFLUENT = 6; // Romeo - display amount paid
    address[4] public collections; // leave one slot empty
    address public tks; // TKS holders are always signallers
    address public creator;
    bool public _collectionsCanVote;
    uint256 public bravoNonce;
    uint256 public kiloNonce;
    uint256 public limaNonce;
    uint256 public charlieNonce;
    uint256 public bsNonce;
    uint256 public lastPrice; // Romeo last price
    uint256[5] public lastVotes; // 0. BRAVO, 1. KILO, 2. LIMA, 3. CHARLIE, 4. Black Spot
    /*//////////////////////////////////////////////////////////////
                            maps to nominations
    //////////////////////////////////////////////////////////////*/
    //maps if user has already voted sig to who
    mapping(address => mapping(uint256 => mapping(address => bool))) public nominations;
    /*//////////////////////////////////////////////////////////////
                            maps to prevOwners
    //////////////////////////////////////////////////////////////*/
    mapping(address => mapping(uint256 => bool)) public pastOwners;
    mapping(uint256 => mapping(uint256 => address)) public owners;
    /*//////////////////////////////////////////////////////////////
                            Votes Map
    //////////////////////////////////////////////////////////////*/
    /// nominated address to votes to signal type
    mapping(address => mapping(uint256 => uint256)) public votes;
    /*//////////////////////////////////////////////////////////////
                            Events
    //////////////////////////////////////////////////////////////*/

    event Reason(address _who, uint256 _sig, string _reason, uint256 nonce);
    event collectionsCanVote(bool);
    event CountResetFor(uint256 index);

    constructor() ERC721("Signal", "SIG") {
        _mint(msg.sender, BRAVO);
        _mint(msg.sender, KILO);
        _mint(msg.sender, LIMA);
        _mint(msg.sender, CHARLIE);
        _mint(msg.sender, BLACK_SPOT);
        _mint(msg.sender, AFFLUENT); // token id must be 6

        
        // tks = 0x6cef68fA559b4822549823D9Bb5Ec9a9323B87B5;
        tks = 0xf5de760f2e916647fd766B4AD9E85ff943cE3A2b;
        collections[0] = address(this); // reserved for affluence
        // Reserved for new collections (eg. soulbound)
        collections[1] = address(0);
        collections[2] = address(0);
        collections[3] = address(0);
        lastPrice = 0;
        creator = msg.sender;
        _collectionsCanVote = false;
    }
    /*//////////////////////////////////////////////////////////////
                            State Mutate
    //////////////////////////////////////////////////////////////*/

    /// @notice sets allowance for collection voting
    /// @dev adjusts the nominate flow
    /// @param set sets the collectionscanvote bool
    function setCollCanVoteBool(bool set) public {
        require(msg.sender == creator, "you cannot set");
        _collectionsCanVote = set;
        emit collectionsCanVote(set);
    }

    /// @notice nominates an address for a signal
    /// @dev can only be called by tks or affluent on init, collections must be enabled
    /// @param who the address being nominated
    /// @param sigInt the signal to send
    /// @param reason the reason for the signal
    function nominate(address who, uint256 sigInt, string calldata reason) external payable nonReentrant {
        require(tx.origin == msg.sender, "Only humans");
        require(who != address(0), "Address is 0");
        if (_collectionsCanVote) {
            require(
                ERC721(tks).balanceOf(msg.sender) > 1 || ERC721(collections[0]).ownerOf(6) == msg.sender
                    || ERC721(collections[1]).balanceOf(msg.sender) > 1 || ERC721(collections[2]).balanceOf(msg.sender) > 1
                    || ERC721(collections[3]).balanceOf(msg.sender) > 1,
                "Not registered to nominate"
            );
        }
        if (!_collectionsCanVote) {
            require(
                ERC721(tks).balanceOf(msg.sender) > 1 || ERC721(collections[0]).ownerOf(6) == msg.sender,
                "only enlisted signallers"
            );
        }
        // if Bravo
        if (sigInt == 1) {
            require(!nominations[msg.sender][0][who], "you have already nominated this address");
            nominations[msg.sender][0][who] = true;
            votes[who][0] += 1;

            if (votes[who][0] > lastVotes[0]) {
                lastVotes[0] = votes[who][0];
                _transfer(ownerOf(BRAVO), who, BRAVO);
                bravoNonce++;
                owners[0][bravoNonce] = who;
                emit Reason(who, sigInt, reason, bravoNonce);
            }
        }
        // if Kilo
        if (sigInt == 2) {
            require(!nominations[msg.sender][1][who], "you have already nominated this address");
            nominations[msg.sender][1][who] = true;
            votes[who][1] += 1;

            if (votes[who][1] > lastVotes[1]) {
                lastVotes[1] = votes[who][1];
                _transfer(ownerOf(KILO), who, KILO);
                kiloNonce++;
                owners[1][kiloNonce] = who;
                emit Reason(who, sigInt, reason, kiloNonce);
            }
        }
        // if Lima
        if (sigInt == 3) {
            require(!nominations[msg.sender][2][who], "you have already nominated this address");
            nominations[msg.sender][2][who] = true;
            votes[who][2] += 1;

            if (votes[who][2] > lastVotes[2]) {
                lastVotes[2] = votes[who][2];
                _transfer(ownerOf(LIMA), who, LIMA);
                limaNonce++;
                owners[2][limaNonce] = who;
                emit Reason(who, sigInt, reason, limaNonce);
            }
        }
        // if CHARLIE
        if (sigInt == 4) {
            require(!nominations[msg.sender][3][who], "you have already nominated this address");
            nominations[msg.sender][3][who] = true;
            votes[who][3] += 1;

            if (votes[who][3] > lastVotes[3]) {
                lastVotes[3] = votes[who][3];
                _transfer(ownerOf(CHARLIE), who, CHARLIE);
                charlieNonce++;
                owners[3][charlieNonce] = who;
                emit Reason(who, sigInt, reason, charlieNonce);
            }
        }
        //if BLACK_SPOT
        if (sigInt == 5) {
            require(!nominations[msg.sender][4][who], "you have already nominated this address");
            nominations[msg.sender][4][who] = true;
            votes[who][4] += 1;

            if (votes[who][4] > lastVotes[4]) {
                lastVotes[4] = votes[who][4];
                _transfer(ownerOf(BLACK_SPOT), who, BLACK_SPOT);
                bsNonce++;
                owners[4][bsNonce] = who;
                emit Reason(who, sigInt, reason, bsNonce);
            }
        }
    }

    /// @notice adds an nft collection for voting
    /// @dev should not overwrite another index unless desired
    /// @param _new the nft collection to add
    /// @param _index the collections index, max of 3
    function updateCollections(address _new, uint256 _index) public {
        require(msg.sender == creator, "not the creator");
        collections[_index] = _new;
    }

    /// @notice awards the affluent romeo signal and allows voting
    /// @dev must send more than previous holder, sends refund to same
    function claimAffluency() external payable {
        require(msg.value > lastPrice, "Insufficient payment");

        address lastClaimer = ownerOf(AFFLUENT);
        uint256 refund = lastPrice;
        uint256 gift = address(this).balance - refund;

        _transfer(lastClaimer, msg.sender, AFFLUENT);
        lastPrice = msg.value;

        bool success = payable(lastClaimer).send(refund);
        if (!success) {
            WETH weth = WETH(0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6);
            weth.deposit{value: refund}();
            require(weth.transfer(lastClaimer, refund), "Payment failed");
        }

        payable(creator).transfer(gift);
    }

    function updateCreator(address _new) public {
        require(msg.sender == creator, "not current creator");
        creator = _new;
    }

    /// @notice allows creator to reset last votes counter for a signal
    /// @dev reserved for emergent use to keep fluid
    /// @param sig the signint id to reset counter of
    function resetCounter(uint256 sig) public {
        require(msg.sender == creator, "only the creator can reset");
        require(lastVotes[sig] > 0, "count not above 1");
        lastVotes[sig] = 0;
        emit CountResetFor(sig);
    }
    /*//////////////////////////////////////////////////////////////
                            View
    //////////////////////////////////////////////////////////////*/

    function tokenURI(uint256 id) public pure override returns (string memory) {
        string[6] memory names = ["BRAVO", "KILO", "LIMA", "CHARLIE", "BLACK_SPOT", "AFFLUENT"];
        string[6] memory paths = [
            string.concat(
                '<path width="350" height="350" fill="#fff" fill-opacity="0.0"/>',
                '<path fill="#F00" stroke="#000" stroke-width="2" d="M175,175 350,350H1V1H355z"/>'
            ),
            string.concat(
                '<rect width="175" height="350" fill="#ff0"/>', '<rect x="175" width="175" height="350" fill="#039"/>'
            ),
            string.concat('<path fill="#FF0" d="M0,0H350V350H0"/>', '<path d="M0,175H350V0H175V350H0"/>'),
            string.concat(
                '<rect width="350" height="350" fill="#039"/>',
                '<rect y="60" width="350" height="230" fill="#fff"/>',
                '<rect y="120" width="350" height="100" fill="#f00"/>'
            ),
            '<circle r="175" cx="175" cy="175" style="fill:Black;stroke:gray;stroke-width:0.1" />',
            '<svg viewBox="0 0 5 5"><path d="M0 0h5v5H0z" fill="red"/><path d="M2 0h1v2h2v1H3v2H2V3H0V2h2z" fill="#ff0"/></svg>'
        ];
        string memory svg =
            string.concat('<svg xmlns="http://www.w3.org/2000/svg" width="350" height="350" >', paths[id - 1], "</svg>");
        string memory json = string.concat(
            '{"name":"Signal code ',
            names[id - 1],
            '","image":"data:image/svg+xml;base64,',
            Base64.encode(bytes(svg)),
            '"}'
        );
        return string.concat("data:application/json;base64,", Base64.encode(bytes(json)));
    }

    function totalSupply() public pure returns (uint256) {
        return 6;
    }

}

interface WETH {
    function deposit() external payable;

    function transfer(address dst, uint256 wad) external returns (bool);

    function balanceOf(address who) external returns (uint256);
}

interface IERC721Ownership {
    function ownerOf(uint256 tokenId) external returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for { let i := 0 } lt(i, len) {} {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out :=
                    add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out :=
                    add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out :=
                    add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
                case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
                case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(
        address indexed owner, address indexed spender, uint256 indexed id
    );

    event ApprovalForAll(
        address indexed owner, address indexed operator, bool approved
    );

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        require(
            msg.sender == owner || isApprovedForAll[owner][msg.sender],
            "NOT_AUTHORIZED"
        );

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved)
        public
        virtual
    {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(address from, address to, uint256 id)
        public
        virtual
    {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender
                == from
                || isApprovedForAll[from][msg.sender]
                || msg.sender
                == getApproved[id],
            "NOT_AUTHORIZED"
        );

        _transfer(from, to, id);
    }

    function _transfer(address from, address to, uint256 id) internal {
        _balanceOf[from]--;
        _balanceOf[to]++;

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    )
        public
        virtual
    {
        transferFrom(from, to, id);

        require(
            to.code.length
                == 0
                || ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data)
                == ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(address from, address to, uint256 id)
        public
        virtual
    {
        safeTransferFrom(from, to, id, "");
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        returns (bool)
    {
        return interfaceId
            == 0x01ffc9a7
            || // ERC165 Interface ID for ERC165
            interfaceId
            == 0x80ac58cd
            || // ERC165 Interface ID for ERC721
            interfaceId
            == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(address, address, uint256, bytes calldata)
        external
        virtual
        returns (bytes4)
    {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}