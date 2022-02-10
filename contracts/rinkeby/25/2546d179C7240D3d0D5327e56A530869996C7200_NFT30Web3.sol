// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.4;

/*
30Web3

ERC721, Enumerable, Ownable, Adminlist

Core is ERC721 library from Solmate by @transmissions11, modified to support
Open Zeppelin Enumerable extension and hooks. Lilownable by @m1guelpf. Adminlist
based on a branch of Open Zeppelin ownership branch from 2018.

ERC721 Solmate: https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol
OZ Enumerable:  https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.4.2/contracts/token/ERC721/extensions/ERC721Enumerable.sol
Lilownable:     https://github.com/m1guelpf/erc721-drop/blob/main/src/LilOwnable.sol
Adminlist:      https://github.com/OpenZeppelin/openzeppelin-contracts/blob/025c9bdcde412e65a307e4985151e7c023fd3870/contracts/ownership/Whitelist.sol

@author kethic, xavier, larkef
*/

/// ----------------------------------------------------------------------------
/// Imports
/// ----------------------------------------------------------------------------
import "./ERC721_Solmate_Hooked.sol";
import "./LilOwnable.sol";
import "./Adminlist.sol";

// Thank you tangert
// https://gist.github.com/tangert/1eceaf04f2877d84fb0e10681b39d7e3#file-renderer-sol
import "./Renderer.sol";

/// ----------------------------------------------------------------------------
/// Enums and Structs
/// ----------------------------------------------------------------------------

/// ----------------------------------------------------------------------------
/// Errors
/// ----------------------------------------------------------------------------
error InvalidToken();
error IndexOutOfBounds();
error TransferFailed();
error NoReentrancy();

contract NFT30Web3 is ERC721, LilOwnable, Adminlist, Renderer {

    /// ------------------------------------------------------------------------
    /// Events
    /// ------------------------------------------------------------------------

    /// ------------------------------------------------------------------------
    /// Variables
    /// ------------------------------------------------------------------------

    uint256 private currentToken;
    string public cohort;
    mapping(uint256 => string) idToCohort;

    uint8 private _mutex = 1;

    /// ------------------------------------------------------------------------
    /// Modifiers
    /// ------------------------------------------------------------------------

    modifier isValidToken(uint256 id) {
        if(ownerOf[id] == address(0)) revert InvalidToken();
        _;
    }

    modifier mutex() {
        if(_mutex == 2) revert NoReentrancy();

        _mutex = 2;
        _;
        _mutex = 1;
    }
    
    /// ------------------------------------------------------------------------
    /// Functions
    /// ------------------------------------------------------------------------

    constructor(
        address[] memory _adminlist,
        string memory _cohort
    ) ERC721 (
        "30Web3 POAP",
        "30Web3"
    ) {

        // Deployer has Admin Rights
        _setupAdmin(msg.sender);

        // Add the other Admins
        uint16 length = uint16(_adminlist.length);
        for(uint16 i=0; i < length; i = uncheckedInc(i))
        {
            _setupAdmin(_adminlist[i]);
        }

        setCohort(_cohort);
    }

    function setCohort(
        string memory _cohort
    )
        public 
        onlyAdmin
    {
        cohort = _cohort;
    }

    function mint(
        address _target
    )
        external
        payable 
        onlyAdmin
        mutex
    {
        _mint(address(_target), currentToken);
        idToCohort[currentToken] = cohort;
        currentToken++;
    }

    function tokenURI(
        uint256 id
    )
        public
        view
        override
        isValidToken(id)
        returns (string memory) 
    {
        string memory svgString = _render(id, idToCohort[id]);
        return buildSvg("30Web3", "Congratulation on your successful completion of 30Web3!!!", svgString);
    }

    function contractURI()
        public
        pure 
        returns (string memory) 
    {
        return '{"name":"30Web3 POAP","description":"Reward for successful completion of 30Web3!","image":"data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNTRweCIgaGVpZ2h0PSI0MHB4IiB2aWV3Qm94PSIwIDAgMzY2IDI2NiIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48ZWxsaXBzZSBjeD0iMTMyIiBjeT0iMTMzLjUiIHJ4PSIxMzIiIHJ5PSIxMzIuNSIgZmlsbD0iI0ZGMDA2RiI+PC9lbGxpcHNlPjxnIHN0eWxlPSJtaXgtYmxlbmQtbW9kZTogY29sb3ItZG9kZ2U7Ij48ZWxsaXBzZSBjeD0iMjM0IiBjeT0iMTMyLjUiIHJ4PSIxMzIiIHJ5PSIxMzIuNSIgZmlsbD0id2hpdGUiPjwvZWxsaXBzZT48L2c+PHBhdGggZmlsbC1ydWxlPSJldmVub2RkIiBjbGlwLXJ1bGU9ImV2ZW5vZGQiIGQ9Ik0xODEuODEyIDEwLjc1ODdDMjMwLjAyMiAzMC40OTIyIDI2NCA3OC4wMTMxIDI2NCAxMzMuNUMyNjQgMTg4LjA3MSAyMzEuMTM1IDIzNC45MzcgMTg0LjE4OCAyNTUuMjQxQzEzNS45NzggMjM1LjUwOCAxMDIgMTg3Ljk4NyAxMDIgMTMyLjVDMTAyIDc3LjkyOTIgMTM0Ljg2NSAzMS4wNjM1IDE4MS44MTIgMTAuNzU4N1oiIGZpbGw9IiNGRjAwRkYiPjwvcGF0aD48Y2lyY2xlIGN4PSIxODMiIGN5PSIxMzIiIHI9IjgxIiBmaWxsPSIjODQzOUVEIj48L2NpcmNsZT48cGF0aCBkPSJNMTQwLjgxNiAxNDMuODg4QzE0MC44MTYgMTQ3LjQyOSAxMzkuOTYzIDE1MC4wMTEgMTM4LjI1NiAxNTEuNjMyQzEzNi41NDkgMTUzLjIxMSAxMzMuNzc2IDE1NCAxMjkuOTM2IDE1NEgxMjEuNzQ0VjE0OS4ySDEzMC41MTJDMTMyLjEzMyAxNDkuMiAxMzMuMzI4IDE0OC44MzcgMTM0LjA5NiAxNDguMTEyQzEzNC44NjQgMTQ3LjM0NCAxMzUuMjQ4IDE0Ni4xNDkgMTM1LjI0OCAxNDQuNTI4VjEzNy45MzZDMTM1LjI0OCAxMzYuNTI4IDEzNC44MjEgMTM1LjQxOSAxMzMuOTY4IDEzNC42MDhDMTMzLjExNSAxMzMuNzU1IDEzMS45ODQgMTMzLjMyOCAxMzAuNTc2IDEzMy4zMjhIMTIzLjcyOFYxMjguNTI4SDEyOS45MzZDMTMxLjI1OSAxMjguNTI4IDEzMi4zNjggMTI4LjEwMSAxMzMuMjY0IDEyNy4yNDhDMTM0LjE2IDEyNi4zOTUgMTM0LjYwOCAxMjUuMjY0IDEzNC42MDggMTIzLjg1NlYxMTguNjA4QzEzNC42MDggMTE2Ljk4NyAxMzQuMjI0IDExNS44MTMgMTMzLjQ1NiAxMTUuMDg4QzEzMi43MzEgMTE0LjM2MyAxMzEuNTU3IDExNCAxMjkuOTM2IDExNEgxMjEuNzQ0VjEwOS4ySDEyOS4xNjhDMTMyLjc5NSAxMDkuMiAxMzUuNTI1IDExMC4wMTEgMTM3LjM2IDExMS42MzJDMTM5LjIzNyAxMTMuMjExIDE0MC4xNzYgMTE1LjcyOCAxNDAuMTc2IDExOS4xODRWMTIzLjIxNkMxNDAuMTc2IDEyNi41MDEgMTM5LjAwMyAxMjguOTc2IDEzNi42NTYgMTMwLjY0QzEzOS40MjkgMTMyLjE3NiAxNDAuODE2IDEzNC44IDE0MC44MTYgMTM4LjUxMlYxNDMuODg4Wk0xNzcuMjM1IDE0My4xMkMxNzcuMjM1IDE0Ni42NjEgMTc2LjI1MyAxNDkuMzcxIDE3NC4yOTEgMTUxLjI0OEMxNzIuMzcxIDE1My4wODMgMTY5Ljc2OCAxNTQgMTY2LjQ4MyAxNTRIMTY1LjIwM0MxNjEuOTE3IDE1NCAxNTkuMjkzIDE1My4wODMgMTU3LjMzMSAxNTEuMjQ4QzE1NS40MTEgMTQ5LjM3MSAxNTQuNDUxIDE0Ni42NjEgMTU0LjQ1MSAxNDMuMTJWMTIwLjA4QzE1NC40NTEgMTE2LjQ5NiAxNTUuNDExIDExMy43ODcgMTU3LjMzMSAxMTEuOTUyQzE1OS4yNTEgMTEwLjExNyAxNjEuODc1IDEwOS4yIDE2NS4yMDMgMTA5LjJIMTY2LjQ4M0MxNjkuODExIDEwOS4yIDE3Mi40MzUgMTEwLjExNyAxNzQuMzU1IDExMS45NTJDMTc2LjI3NSAxMTMuNzg3IDE3Ny4yMzUgMTE2LjQ5NiAxNzcuMjM1IDEyMC4wOFYxNDMuMTJaTTE3MS43OTUgMTE4Ljg2NEMxNzEuNzk1IDExNy41NDEgMTcxLjI4MyAxMTYuNDExIDE3MC4yNTkgMTE1LjQ3MkMxNjkuMjc3IDExNC40OTEgMTY4LjAxOSAxMTQgMTY2LjQ4MyAxMTRIMTY1LjIwM0MxNjMuNjY3IDExNCAxNjIuMzg3IDExNC40OTEgMTYxLjM2MyAxMTUuNDcyQzE2MC4zODEgMTE2LjQxMSAxNTkuODkxIDExNy41NDEgMTU5Ljg5MSAxMTguODY0VjEzNi4yMDhMMTcxLjc5NSAxMTguODY0Wk0xNTkuODkxIDE0NC4zMzZDMTU5Ljg5MSAxNDUuNjU5IDE2MC4zODEgMTQ2LjgxMSAxNjEuMzYzIDE0Ny43OTJDMTYyLjM4NyAxNDguNzMxIDE2My42NjcgMTQ5LjIgMTY1LjIwMyAxNDkuMkgxNjYuNDgzQzE2OC4wMTkgMTQ5LjIgMTY5LjI3NyAxNDguNzMxIDE3MC4yNTkgMTQ3Ljc5MkMxNzEuMjgzIDE0Ni44MTEgMTcxLjc5NSAxNDUuNjU5IDE3MS43OTUgMTQ0LjMzNlYxMjcuMDU2TDE1OS44OTEgMTQ0LjMzNlpNMjAwLjI3NyAxMzUuODI0TDE5Ni4yNDUgMTU0SDE4OC41NjVMMTg2LjM4OSAxMDkuMkgxOTEuMTI1TDE5My4wNDUgMTQ5LjJMMTk4LjM1NyAxMjguMDhIMjAyLjMyNUwyMDcuNzY1IDE0OS4yTDIwOS43NDkgMTA5LjJIMjE0LjE2NUwyMTEuOTg5IDE1NEgyMDMuOTI1TDIwMC4yNzcgMTM1LjgyNFpNMjQ0LjUwNCAxNDMuODg4QzI0NC41MDQgMTQ3LjQyOSAyNDMuNjUgMTUwLjAxMSAyNDEuOTQ0IDE1MS42MzJDMjQwLjIzNyAxNTMuMjExIDIzNy40NjQgMTU0IDIzMy42MjQgMTU0SDIyNS40MzJWMTQ5LjJIMjM0LjJDMjM1LjgyMSAxNDkuMiAyMzcuMDE2IDE0OC44MzcgMjM3Ljc4NCAxNDguMTEyQzIzOC41NTIgMTQ3LjM0NCAyMzguOTM2IDE0Ni4xNDkgMjM4LjkzNiAxNDQuNTI4VjEzNy45MzZDMjM4LjkzNiAxMzYuNTI4IDIzOC41MDkgMTM1LjQxOSAyMzcuNjU2IDEzNC42MDhDMjM2LjgwMiAxMzMuNzU1IDIzNS42NzIgMTMzLjMyOCAyMzQuMjY0IDEzMy4zMjhIMjI3LjQxNlYxMjguNTI4SDIzMy42MjRDMjM0Ljk0NiAxMjguNTI4IDIzNi4wNTYgMTI4LjEwMSAyMzYuOTUyIDEyNy4yNDhDMjM3Ljg0OCAxMjYuMzk1IDIzOC4yOTYgMTI1LjI2NCAyMzguMjk2IDEyMy44NTZWMTE4LjYwOEMyMzguMjk2IDExNi45ODcgMjM3LjkxMiAxMTUuODEzIDIzNy4xNDQgMTE1LjA4OEMyMzYuNDE4IDExNC4zNjMgMjM1LjI0NSAxMTQgMjMzLjYyNCAxMTRIMjI1LjQzMlYxMDkuMkgyMzIuODU2QzIzNi40ODIgMTA5LjIgMjM5LjIxMyAxMTAuMDExIDI0MS4wNDggMTExLjYzMkMyNDIuOTI1IDExMy4yMTEgMjQzLjg2NCAxMTUuNzI4IDI0My44NjQgMTE5LjE4NFYxMjMuMjE2QzI0My44NjQgMTI2LjUwMSAyNDIuNjkgMTI4Ljk3NiAyNDAuMzQ0IDEzMC42NEMyNDMuMTE3IDEzMi4xNzYgMjQ0LjUwNCAxMzQuOCAyNDQuNTA0IDEzOC41MTJWMTQzLjg4OFoiIGZpbGw9IndoaXRlIj48L3BhdGg+PC9zdmc+","external_link":"https://twitter.com/wslyvh","fee_recipient":"0x63cab69189dBa2f1544a25c8C19b4309f415c8AA","seller_fee_basis_points":0}';
    }

    function withdraw()
        external
        onlyAdmin
    {
        safeTransferETH(msg.sender, address(this).balance);
    }

    /// ------------------------------------------------------------------------
    /// ERC721Enumerable Variables
    /// ------------------------------------------------------------------------

    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /// ------------------------------------------------------------------------
    /// ERC721Enumerable Functions
    /// ------------------------------------------------------------------------

    function tokenOfOwnerByIndex(
        address owner,
        uint256 index
    )
        public
        view
        returns (uint256) 
    {
        if(index >= ERC721.balanceOf[owner]) revert IndexOutOfBounds();
        return _ownedTokens[owner][index];
    }

    function totalSupply()
        public
        view
        returns (uint256)
    {
        return _allTokens.length;
    }

    function tokenByIndex(
        uint256 index
    )
        public
        view
        returns (uint256) 
    {
        if(index >= totalSupply()) revert IndexOutOfBounds();
        return _allTokens[index];
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);   
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    function _addTokenToOwnerEnumeration(
        address to,
        uint256 tokenId
    )
        private
    {
        uint256 length = ERC721.balanceOf[to];
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    function _addTokenToAllTokensEnumeration(
        uint256 tokenId
    )
        private
    {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    function _removeTokenFromOwnerEnumeration(
        address from, 
        uint256 tokenId
    )
        private 
    {
        uint256 lastTokenIndex = ERC721.balanceOf[from] - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];
        uint256 lastTokenId = _allTokens[lastTokenIndex];
        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }


    /// ------------------------------------------------------------------------
    /// ERC165
    /// ------------------------------------------------------------------------

    function supportsInterface(bytes4 interfaceId)
        public
        pure
        override(ERC721, LilOwnable)
        returns (bool)
    {
        return
        interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
        interfaceId == 0x7f5828d0 || // ERC165 Interface ID for ERC173
        interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
        interfaceId == 0x5b5e139f || // ERC165 Interface ID for ERC721Metadata
        interfaceId == 0x780e9d63;   // ERC165 Interface ID for ERC721Enumerable
    }

    /// ------------------------------------------------------------------------
    /// Utility Functions
    /// ------------------------------------------------------------------------

    //https://ethereum.stackexchange.com/questions/8346/convert-address-to-string
    function toAsciiString(
        address x
    )   
        internal
        pure 
        returns (string memory) 
    {
        bytes memory s = new bytes(40);
        for (uint256 i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint256(uint160(x)) / (2**(8 * (19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i] = char(hi);
            s[2 * i + 1] = char(lo);
        }
        return string(s);
    }

    function buildSvg(
        string memory nftName,
        string memory nftDescription,
        string memory svgString
    ) 
        public 
        pure 
        returns (string memory) 
    {
        string memory imgEncoded = Base64.encode(bytes(svgString));
        string memory imgURI = string(
            abi.encodePacked("data:image/svg+xml;base64,", imgEncoded)
        );
        string memory nftJson = string(
            abi.encodePacked(
                '{"name": "',
                nftName,
                '", "description": "',
                nftDescription,
                '", "image": "',
                imgURI,
                '"}'
            )
        );
        string memory nftEncoded = Base64.encode(bytes(nftJson));
        string memory finalURI = string(
            abi.encodePacked("data:application/json;base64,", nftEncoded)
        );
        return finalURI;
    }

    function char(
        bytes1 b
    )
        internal
        pure 
        returns (bytes1 c)
    {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    // https://gist.github.com/hrkrshnn/ee8fabd532058307229d65dcd5836ddc#the-increment-in-for-loop-post-condition-can-be-made-unchecked
    function uncheckedInc(
        uint16 i
    )
        internal
        pure 
        returns (uint16) 
    {
        unchecked {
            return i + 1;
        }
    }

    // https://github.com/Rari-Capital/solmate/blob/af8adfb66c867bc085c81018e22a98e8a9c66c20/src/utils/SafeTransferLib.sol#L16
    function safeTransferETH(
        address to,
        uint256 amount
    ) 
        internal 
    {

        bool callStatus;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            callStatus := call(gas(), to, amount, 0, 0, 0, 0)
        }

        if(!callStatus) revert TransferFailed();
    }
}

/// ----------------------------------------------------------------------------
/// External Contracts
/// ----------------------------------------------------------------------------

// Primes NFT
//https://etherscan.io/address/0xBDA937F5C5f4eFB2261b6FcD25A71A1C350FdF20#code#L1507
library Base64 {
    string internal constant TABLE_ENCODE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(18, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1)
                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(12, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1)
                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(6, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.4;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
/// @dev Note that balanceOf does not revert if passed the zero address, in defiance of the ERC.
abstract contract ERC721 {
    /*///////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*///////////////////////////////////////////////////////////////
                          METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*///////////////////////////////////////////////////////////////
                            ERC721 STORAGE                        
    //////////////////////////////////////////////////////////////*/

    mapping(address => uint256) public balanceOf;

    mapping(uint256 => address) public ownerOf;

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*///////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || msg.sender == getApproved[id] || isApprovedForAll[from][msg.sender],
            "NOT_AUTHORIZED"
        );

        _beforeTokenTransfer(from, to, id);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            balanceOf[from]--;

            balanceOf[to]++;
        }

        ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*///////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(ownerOf[id] == address(0), "ALREADY_MINTED");

        _beforeTokenTransfer(address(0), to, id);

        // Counter overflow is incredibly unrealistic.
        unchecked {
            balanceOf[to]++;
        }

        ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = ownerOf[id];

        require(ownerOf[id] != address(0), "NOT_MINTED");

        _beforeTokenTransfer(ERC721.ownerOf[id], address(0), id);

        // Ownership check above ensures no underflow.
        unchecked {
            balanceOf[owner]--;
        }

        delete ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /**
     * @dev OZ Hook that is called before any token transfer. This includes minting
     * and burning. For adding ERC721Enumerable functionality.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
interface ERC721TokenReceiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 id,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.4;

error NotOwner();

abstract contract LilOwnable {
    address internal _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = msg.sender;
    }

    function owner() external view returns (address) {
        return _owner;
    }

    function transferOwnership(address _newOwner) external {
        if (msg.sender != _owner) revert NotOwner();

        _owner = _newOwner;
    }

    function renounceOwnership() public {
        if (msg.sender != _owner) revert NotOwner();

        _owner = address(0);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        pure
        virtual
        returns (bool)
    {
        return interfaceId == 0x7f5828d0; // ERC165 Interface ID for ERC173
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/*
* @author: kethcode
*/

/// ----------------------------------------------------------------------------
/// Errors
/// ----------------------------------------------------------------------------

error NotAdmin();

abstract contract Adminlist {

    /// ------------------------------------------------------------------------
    /// Events
    /// ------------------------------------------------------------------------

    event AdminAddressAdded(address addr);
    event AdminAddressRemoved(address addr);

    /// ------------------------------------------------------------------------
    /// Variables
    /// ------------------------------------------------------------------------

    mapping(address => bool) public adminlist;

    /// ------------------------------------------------------------------------
    /// Modifiers
    /// ------------------------------------------------------------------------

    modifier onlyAdmin()
    {
        if(!adminlist[msg.sender]) revert NotAdmin();
        _;
    }

    /// ------------------------------------------------------------------------
    /// Functions
    /// ------------------------------------------------------------------------

    function addAddressToAdminlist(address addr) 
        public 
        onlyAdmin
        returns(bool success) 
    {
        if (!adminlist[addr]) {
            adminlist[addr] = true;
            emit AdminAddressAdded(addr);
            success = true; 
        }
    }

    function removeAddressFromAdminlist(address addr) 
        public 
        onlyAdmin
        returns(bool success) 
    {
        if (adminlist[addr]) {
            adminlist[addr] = false;
            emit AdminAddressRemoved(addr);
            success = true;
        }
    }

    function _setupAdmin(address addr) 
        internal 
        virtual 
    {
        adminlist[addr] = true;
        emit AdminAddressAdded(addr);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.6.0 <0.9.0;

// Thank you OpenZeppelin
import "@openzeppelin/contracts/utils/Strings.sol";

// Thank you tangert
// https://gist.github.com/tangert/1eceaf04f2877d84fb0e10681b39d7e3#file-renderer-sol

// Thanks GeeksForGeeks
// https://www.geeksforgeeks.org/random-number-generator-in-solidity-using-keccak256/

contract Renderer {
    constructor() {}

    function _render(uint256 id, string memory cohort)
        public
        pure
        returns (string memory)
    {
        string memory gradientStart = string(
            abi.encodePacked(
                "hsla(",
                Strings.toString(generateHighlightHue(id)),
                ", 100%, 50%, 1)"
            )
        );
        string memory gradientEnd = "hsla(250, 64%, 45%, 1)";
        string memory allGradients = renderAllGradients(
            gradientEnd,
            gradientStart
        );
        return
            string(
                abi.encodePacked(
                    '<svg width="500" height="500" viewBox="0 0 500 500" fill="none" xmlns="http://www.w3.org/2000/svg"><rect x="0.5" y="3.5" width="496" height="496" rx="41.5" fill="#8F8F8F" stroke="#838383" /><rect x="7.5" y="0.5" width="492" height="493" rx="41.5" fill="#EFEFEF" stroke="#C0C0C0" /><text x="352" y="64" fill="url(#titleGradient)" font-size="48px" font-weight="900" line-height="58px" letter-spacing="-2px" font-family="Inter,Arial,Helvetica,Apple Color Emoji,Segoe UI Emoji,NotoColorEmoji,Noto Color Emoji,Segoe UI Symbol,Android Emoji,EmojiSymbols,-apple-system,BlinkMacSystemFont,Segoe UI,Roboto,Helvetica Neue,Noto Sans,sans-serif">30W3</text><text x="34" y="442" fill="url(#graduationGradient)" font-size="28px" font-weight="800" line-height="29px" letter-spacing="-1px" font-family="Inter,Arial,Helvetica,Apple Color Emoji,Segoe UI Emoji,NotoColorEmoji,Noto Color Emoji,Segoe UI Symbol,Android Emoji,EmojiSymbols,-apple-system,BlinkMacSystemFont,Segoe UI,Roboto,Helvetica Neue,Noto Sans,sans-serif">Graduation</text><text x="34" y="464" fill="#29295E" font-size="22px" font-weight="bold" line-height="22px" letter-spacing="-1px" font-family="Inter,Arial,Helvetica,Apple Color Emoji,Segoe UI Emoji,NotoColorEmoji,Noto Color Emoji,Segoe UI Symbol,Android Emoji,EmojiSymbols,-apple-system,BlinkMacSystemFont,Segoe UI,Roboto,Helvetica Neue,Noto Sans,sans-serif">',
                    cohort,
                    '</text><path id="diskEye" d="M250 156.975C196.884 156.975 147.486 188.44 131.859 238.309C142.609 285.427 196.884 319.642 250 319.642C303.116 319.642 354.992 288.177 368.141 238.309C352.332 188.44 303.116 156.975 250 156.975Z" fill="url(#diskEyeGradient)" /><path id="diskBottom" d="M250 316.642C196.884 316.642 151.313 284.34 131.859 238.309C125.381 253.638 121.798 270.489 121.798 288.177C121.798 358.982 179.196 416.38 250 416.38C320.804 416.38 378.202 358.982 378.202 288.177C378.202 270.489 374.62 253.638 368.141 238.309C348.687 284.34 303.116 316.642 250 316.642Z" fill="url(#diskBottomGradient)" /><path id="diskTop" d="M250 159.975C303.116 159.975 348.687 192.277 368.141 238.309C374.62 222.98 378.202 206.128 378.202 188.44C378.202 117.636 320.804 60.2375 250 60.2375C179.196 60.2375 121.798 117.636 121.798 188.44C121.798 206.128 125.381 222.98 131.859 238.309C151.313 192.277 196.884 159.975 250 159.975Z" fill="url(#diskTopGradient)" /><path id="diskPupil" d="M250 288.177C277.542 288.177 299.869 265.85 299.869 238.309C299.869 210.767 277.542 188.44 250 188.44C222.458 188.44 200.131 210.767 200.131 238.309C200.131 265.85 222.458 288.177 250 288.177Z" fill="url(#diskPupilGradient)" /><defs>',
                    allGradients,
                    '<linearGradient id="diskPupilGradient" x1="213.346" y1="202.702" x2="283.18" y2="270.54" gradientUnits="userSpaceOnUse"><stop stop-color="white" stop-opacity="0.8" /><stop offset="1" stop-color="white" stop-opacity="0.4" /></linearGradient></defs></svg>'
                )
            );
    }

    function renderGradient(
        string memory gradientStart,
        string memory gradientEnd,
        string memory id,
        string memory x1,
        string memory y1,
        string memory x2,
        string memory y2
    ) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<linearGradient id="',
                    id,
                    '" x1="',
                    x1,
                    '" y1="',
                    y1,
                    '" x2="',
                    x2,
                    '" y2="',
                    y2,
                    '"  gradientUnits="userSpaceOnUse">',
                    '<stop stop-color="',
                    gradientStart,
                    '" /><stop offset="1" stop-color="',
                    gradientEnd,
                    '" /></linearGradient>'
                )
            );
    }

    function renderAllGradients(
        string memory gradientStart,
        string memory gradientEnd
    ) private pure returns (string memory) {
        string memory titleGradient = renderGradient(
            gradientStart,
            gradientEnd,
            "titleGradient",
            "352",
            "452",
            "64",
            "100"
        );
        string memory graduationGradient = renderGradient(
            gradientStart,
            gradientEnd,
            "graduationGradient",
            "34",
            "170",
            "442",
            "472"
        );
        string memory diskEyeGradient = renderGradient(
            gradientEnd,
            gradientStart,
            "diskEyeGradient",
            "379.203",
            "80.7484",
            "144.731",
            "367.874"
        );
        string memory diskBottomGradient = renderGradient(
            gradientEnd,
            gradientStart,
            "diskBottomGradient",
            "360.817",
            "349.878",
            "132.361",
            "268.073"
        );
        string memory diskTopGradient = renderGradient(
            gradientEnd,
            gradientStart,
            "diskTopGradient",
            "138.53",
            "119.249",
            "372.108",
            "225.058"
        );
        return
            string(
                abi.encodePacked(
                    titleGradient,
                    graduationGradient,
                    diskEyeGradient,
                    diskBottomGradient,
                    diskTopGradient
                )
            );
    }

    // In HSL color mode, the "H" parameters varies from 0 to 359
    function generateHighlightHue(uint256 id) private pure returns (uint256) {
        return
            uint256(keccak256(abi.encodePacked(id, "somesaltysalt", id))) % 359;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}