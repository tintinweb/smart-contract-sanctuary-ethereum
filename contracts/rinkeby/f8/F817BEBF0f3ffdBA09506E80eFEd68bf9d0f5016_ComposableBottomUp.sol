// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "./interfaces/IERC998ERC721BottomUp.sol";
import "./interfaces/IERC998ERC721BottomUpEnumerable.sol";

contract ComposableBottomUp is
    ERC165,
    IERC721,
    IERC998ERC721BottomUp,
    IERC998ERC721BottomUpEnumerable
{
    using SafeMath for uint256;
    struct TokenOwner {
        address tokenOwner;
        uint256 parentTokenId;
    }

    // return this.rootOwnerOf.selector ^ this.rootOwnerOfChild.selector ^
    //   this.tokenOwnerOf.selector ^ this.ownerOfChild.selector;
    bytes32 constant ERC998_MAGIC_VALUE = 0x00000000000000000000000000000000000000000000000000000000cd740db5;

    // tokenId => token owner
    mapping(uint256 => TokenOwner) internal tokenIdToTokenOwner;

    // root token owner address => (tokenId => approved address)
    mapping(address => mapping(uint256 => address))
        internal rootOwnerAndTokenIdToApprovedAddress;

    // token owner address => token count
    mapping(address => uint256) internal tokenOwnerToTokenCount;

    // token owner => (operator address => bool)
    mapping(address => mapping(address => bool)) internal tokenOwnerToOperators;

    // parent address => (parent tokenId => array of child tokenIds)
    mapping(address => mapping(uint256 => uint256[]))
        private parentToChildTokenIds;

    // tokenId => position in childTokens array
    mapping(uint256 => uint256) private tokenIdToChildTokenIdsIndex;

    // wrapper on minting new 721
    /*
    function mint721(address _to) public returns(uint256) {
      _mint(_to, allTokens.length + 1);
      return allTokens.length;
    }
    */
    //from zepellin ERC721Receiver.sol
    //old version
    bytes4 constant ERC721_RECEIVED = 0x150b7a02;

    function isContract(address _addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }

    function _tokenOwnerOf(uint256 _tokenId)
        internal
        view
        returns (
            address tokenOwner,
            uint256 parentTokenId,
            bool isParent
        )
    {
        tokenOwner = tokenIdToTokenOwner[_tokenId].tokenOwner;
        require(
            tokenOwner != address(0),
            "ComposableBottomUp: _tokenOwnerOf tokenOwner zero address"
        );
        parentTokenId = tokenIdToTokenOwner[_tokenId].parentTokenId;
        if (parentTokenId > 0) {
            isParent = true;
            parentTokenId--;
        } else {
            isParent = false;
        }
        return (tokenOwner, parentTokenId, isParent);
    }

    function tokenOwnerOf(uint256 _tokenId)
        external
        view
        override
        returns (
            bytes32 tokenOwner,
            uint256 parentTokenId,
            bool isParent
        )
    {
        address tokenOwnerAddress = tokenIdToTokenOwner[_tokenId].tokenOwner;
        require(tokenOwnerAddress != address(0), "ComposableBottomUp: tokenOwnerOf tokenOwnerAddress zero address");
        parentTokenId = tokenIdToTokenOwner[_tokenId].parentTokenId;
        if (parentTokenId > 0) {
            isParent = true;
            parentTokenId--;
        } else {
            isParent = false;
        }
        return (
            (ERC998_MAGIC_VALUE << 224) |
                bytes32(uint256(uint160(tokenOwnerAddress))),
            parentTokenId,
            isParent
        );
    }

    // Use Cases handled:
    // Case 1: Token owner is this contract and no parent tokenId.
    // Case 2: Token owner is this contract and token
    // Case 3: Token owner is top-down composable
    // Case 4: Token owner is an unknown contract
    // Case 5: Token owner is a user
    // Case 6: Token owner is a bottom-up composable
    // Case 7: Token owner is ERC721 token owned by top-down token
    // Case 8: Token owner is ERC721 token owned by unknown contract
    // Case 9: Token owner is ERC721 token owned by user
    function rootOwnerOf(uint256 _tokenId)
        public
        view
        override
        returns (bytes32 rootOwner)
    {
        address rootOwnerAddress = tokenIdToTokenOwner[_tokenId].tokenOwner;
        require(
            rootOwnerAddress != address(0),
            "ComposableBottomUp: rootOwnerOf rootOwnerAddress zero address"
        );
        uint256 parentTokenId = tokenIdToTokenOwner[_tokenId].parentTokenId;
        bool isParent = parentTokenId > 0;
        parentTokenId--;
        bytes memory callData;
        bytes memory data;
        bool callSuccess;

        if ((rootOwnerAddress == address(this))) {
            do {
                if (isParent == false) {
                    // Case 1: Token owner is this contract and no token.
                    // This case should not happen.
                    return
                        (ERC998_MAGIC_VALUE << 224) |
                        bytes32(uint256(uint160(rootOwnerAddress)));
                } else {
                    // Case 2: Token owner is this contract and token
                    (rootOwnerAddress, parentTokenId, isParent) = _tokenOwnerOf(
                        parentTokenId
                    );
                }
            } while (rootOwnerAddress == address(this));
            _tokenId = parentTokenId;
        }

        if (isParent == false) {
            // success if this token is owned by a top-down token
            // 0xed81cdda == rootOwnerOfChild(address, uint256)
            callData = abi.encodeWithSelector(
                0xed81cdda,
                address(this),
                _tokenId
            );
            (callSuccess, data) = rootOwnerAddress.staticcall(callData);
            if (callSuccess) {
                assembly {
                    rootOwner := mload(add(data, 0x20))
                }
            }
            if (callSuccess == true && rootOwner >> 224 == ERC998_MAGIC_VALUE) {
                // Case 3: Token owner is top-down composable
                return rootOwner;
            } else {
                // Case 4: Token owner is an unknown contract
                // Or
                // Case 5: Token owner is a user
                return
                    (ERC998_MAGIC_VALUE << 224) |
                    bytes32(uint256(uint160(rootOwnerAddress)));
            }
        } else {
            // 0x43a61a8e == rootOwnerOf(uint256)
            callData = abi.encodeWithSelector(0x43a61a8e, parentTokenId);
            (callSuccess, data) = rootOwnerAddress.staticcall(callData);
            if (callSuccess) {
                assembly {
                    rootOwner := mload(add(data, 0x20))
                }
            }
            if (callSuccess == true && rootOwner >> 224 == ERC998_MAGIC_VALUE) {
                // Case 6: Token owner is a bottom-up composable
                // Or
                // Case 2: Token owner is top-down composable
                return rootOwner;
            } else {
                // token owner is ERC721
                address childContract = rootOwnerAddress;
                //0x6352211e == "ownerOf(uint256)"
                callData = abi.encodeWithSelector(0x6352211e, parentTokenId);
                (callSuccess, data) = rootOwnerAddress.staticcall(callData);
                if (callSuccess) {
                    assembly {
                        rootOwnerAddress := mload(add(data, 0x20))
                    }
                }
                require(callSuccess, "Call to ownerOf failed");

                // 0xed81cdda == rootOwnerOfChild(address,uint256)
                callData = abi.encodeWithSelector(
                    0xed81cdda,
                    childContract,
                    parentTokenId
                );

                (callSuccess, data) = rootOwnerAddress.staticcall(callData);
                if (callSuccess) {
                    assembly {
                        rootOwner := mload(add(data, 0x20))
                    }
                }
                if (
                    callSuccess == true &&
                    rootOwner >> 224 == ERC998_MAGIC_VALUE
                ) {
                    // Case 7: Token owner is ERC721 token owned by top-down token
                    return rootOwner;
                } else {
                    // Case 8: Token owner is ERC721 token owned by unknown contract
                    // Or
                    // Case 9: Token owner is ERC721 token owned by user
                    return
                        (ERC998_MAGIC_VALUE << 224) |
                        bytes32(uint256(uint160(rootOwnerAddress)));
                }
            }
        }
    }

    /**
     * In a bottom-up composable authentication to transfer etc. is done by getting the rootOwner by finding the parent token
     * and then the parent token of that one until a final owner address is found.  If the msg.sender is the rootOwner or is
     * approved by the rootOwner then msg.sender is authenticated and the action can occur.
     * This enables the owner of the top-most parent of a tree of composables to call any method on child composables.
     */
    // returns the root owner at the top of the tree of composables
    function ownerOf(uint256 _tokenId) external view override returns (address) {
        address tokenOwner = tokenIdToTokenOwner[_tokenId].tokenOwner;
        require(
            tokenOwner != address(0),
            "ComposableBottomUp: ownerOf tokenOwner zero address"
        );
        return tokenOwner;
    }

    function balanceOf(address _tokenOwner)
        external
        view
        override
        returns (uint256)
    {
        require(
            _tokenOwner != address(0),
            "ComposableBottomUp: balanceOf _tokenOwner zero address"
        );
        return tokenOwnerToTokenCount[_tokenOwner];
    }

    function approve(address _approved, uint256 _tokenId) external override {
        address tokenOwner = tokenIdToTokenOwner[_tokenId].tokenOwner;
        require(tokenOwner != address(0), "ComposableBottomUp: approve tokenOwner zero address");
        address rootOwner = address(uint160(uint256(rootOwnerOf(_tokenId))));
        require(
            rootOwner == msg.sender ||
                tokenOwnerToOperators[rootOwner][msg.sender],
            "ComposableBottomUp: approve msg.sender not eligible"
        );

        rootOwnerAndTokenIdToApprovedAddress[rootOwner][_tokenId] = _approved;
        emit Approval(rootOwner, _approved, _tokenId);
    }

    function getApproved(uint256 _tokenId)
        external
        view
        override
        returns (address)
    {
        address rootOwner = address(uint160(uint256(rootOwnerOf(_tokenId))));
        return rootOwnerAndTokenIdToApprovedAddress[rootOwner][_tokenId];
    }

    function setApprovalForAll(address _operator, bool _approved)
        external
        override
    {
        require(_operator != address(0), "ComposableBottomUp: setApprovalForAll _operator zero address");
        tokenOwnerToOperators[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function isApprovedForAll(address _owner, address _operator)
        external
        view
        override
        returns (bool)
    {
        require(_owner != address(0), "ComposableBottomUp: isApprovedForAll _owner zero address");
        require(_operator != address(0), "ComposableBottomUp: isApprovedForAll _operator zero address");
        return tokenOwnerToOperators[_owner][_operator];
    }

    function removeChild(
        address _fromContract,
        uint256 _fromTokenId,
        uint256 _tokenId
    ) internal {
        uint256 childTokenIndex = tokenIdToChildTokenIdsIndex[_tokenId];
        uint256 lastChildTokenIndex =
            parentToChildTokenIds[_fromContract][_fromTokenId].length - 1;
        uint256 lastChildTokenId =
            parentToChildTokenIds[_fromContract][_fromTokenId][
                lastChildTokenIndex
            ];

        if (_tokenId != lastChildTokenId) {
            parentToChildTokenIds[_fromContract][_fromTokenId][
                childTokenIndex
            ] = lastChildTokenId;
            tokenIdToChildTokenIdsIndex[lastChildTokenId] = childTokenIndex;
        }
        // parentToChildTokenIds[_fromContract][_fromTokenId].length--;
        // added:
        parentToChildTokenIds[_fromContract][_fromTokenId].pop();
    }

    function authenticateAndClearApproval(uint256 _tokenId) private {
        address rootOwner = address(uint160(uint256(rootOwnerOf(_tokenId))));
        address approvedAddress =
            rootOwnerAndTokenIdToApprovedAddress[rootOwner][_tokenId];
        require(
            rootOwner == msg.sender ||
                tokenOwnerToOperators[rootOwner][msg.sender] ||
                approvedAddress == msg.sender,
            "ComposableBottomUp: authenticateAndClearApproval msg.sender not eligible"
        );

        // clear approval
        if (approvedAddress != address(0)) {
            delete rootOwnerAndTokenIdToApprovedAddress[rootOwner][_tokenId];
            emit Approval(rootOwner, address(0), _tokenId);
        }
    }

    function transferFromParent(
        address _fromContract,
        uint256 _fromTokenId,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) external override {
        require(tokenIdToTokenOwner[_tokenId].tokenOwner == _fromContract, "ComposableBottomUp: transferFromParent tokenOwner != _fromContract");
        require(_to != address(0), "ComposableBottomUp: transferFromParent _to zero address");
        uint256 parentTokenId = tokenIdToTokenOwner[_tokenId].parentTokenId;
        require(parentTokenId != 0, "ComposableBottomUp: transferFromParent token does not have a parent token.");
        require(parentTokenId - 1 == _fromTokenId, "ComposableBottomUp: transferFromParent _fromTokenId not matching parentTokenId");
        authenticateAndClearApproval(_tokenId);

        // remove and transfer token
        if (_fromContract != _to) {
            assert(tokenOwnerToTokenCount[_fromContract] > 0);
            tokenOwnerToTokenCount[_fromContract]--;
            tokenOwnerToTokenCount[_to]++;
        }

        tokenIdToTokenOwner[_tokenId].tokenOwner = _to;
        tokenIdToTokenOwner[_tokenId].parentTokenId = 0;

        removeChild(_fromContract, _fromTokenId, _tokenId);
        delete tokenIdToChildTokenIdsIndex[_tokenId];

        if (isContract(_to)) {
            bytes4 retval =
                IERC721Receiver(_to).onERC721Received(
                    msg.sender,
                    _fromContract,
                    _tokenId,
                    _data
                );
            require(retval == ERC721_RECEIVED, "ComposableBottomUp: transferFromParent onERC721Received invalid value");
        }

        emit Transfer(_fromContract, _to, _tokenId);
        emit TransferFromParent(_fromContract, _fromTokenId, _tokenId);
    }

    function transferToParent(
        address _from,
        address _toContract,
        uint256 _toTokenId,
        uint256 _tokenId,
        bytes memory _data
    ) external override {
        require(_from != address(0), "ComposableBottomUp: transferToParent _from zero address");
        require(tokenIdToTokenOwner[_tokenId].tokenOwner == _from, "ComposableBottomUp: transferToParent tokenOwner != _from");
        require(_toContract != address(0), "ComposableBottomUp: transferToParent _toContract zero address");
        require(
            tokenIdToTokenOwner[_tokenId].parentTokenId == 0,
            "ComposableBottomUp: transferToParent Cannot transfer from address when owned by a token."
        );
        address approvedAddress =
            rootOwnerAndTokenIdToApprovedAddress[_from][_tokenId];
        if (msg.sender != _from) {
            // 0xed81cdda == rootOwnerOfChild(address,uint256)
            bytes memory callData =
                abi.encodeWithSelector(0xed81cdda, address(this), _tokenId);
            (bool callSuccess, bytes memory data) = _from.staticcall(callData);
            if (callSuccess == true) {
                bytes32 rootOwner;
                assembly {
                    rootOwner := mload(add(data, 0x20))
                }
                require(
                    rootOwner >> 224 != ERC998_MAGIC_VALUE,
                    "ComposableBottomUp: transferToParent Token is child of other top down composable"
                );
            }
            require(
                tokenOwnerToOperators[_from][msg.sender] ||
                    approvedAddress == msg.sender,
                    "ComposableBottomUp: transferToParent msg.sender is not eligible"
            );
        }

        // clear approval
        if (approvedAddress != address(0)) {
            delete rootOwnerAndTokenIdToApprovedAddress[_from][_tokenId];
            emit Approval(_from, address(0), _tokenId);
        }

        // remove and transfer token
        if (_from != _toContract) {
            assert(tokenOwnerToTokenCount[_from] > 0);
            tokenOwnerToTokenCount[_from]--;
            tokenOwnerToTokenCount[_toContract]++;
        }
        TokenOwner memory parentToken =
            TokenOwner(_toContract, _toTokenId.add(1));
        tokenIdToTokenOwner[_tokenId] = parentToken;
        uint256 index = parentToChildTokenIds[_toContract][_toTokenId].length;
        parentToChildTokenIds[_toContract][_toTokenId].push(_tokenId);
        tokenIdToChildTokenIdsIndex[_tokenId] = index;

        require(
            IERC721(_toContract).ownerOf(_toTokenId) != address(0),
            "ComposableBottomUp: transferToParent _toTokenId does not exist"
        );

        emit Transfer(_from, _toContract, _tokenId);
        emit TransferToParent(_toContract, _toTokenId, _tokenId);
    }

    function transferAsChild(
        address _fromContract,
        uint256 _fromTokenId,
        address _toContract,
        uint256 _toTokenId,
        uint256 _tokenId,
        bytes memory _data
    ) external override {
        require(tokenIdToTokenOwner[_tokenId].tokenOwner == _fromContract, "ComposableBottomUp: transferAsChild tokenOwner != _fromContract");
        require(_toContract != address(0), "ComposableBottomUp: transferAsChild _toContract zero address");
        uint256 parentTokenId = tokenIdToTokenOwner[_tokenId].parentTokenId;
        require(parentTokenId > 0, "ComposableBottomUp: transferAsChild No parent token to transfer from.");
        require(parentTokenId - 1 == _fromTokenId, "ComposableBottomUp: transferAsChild parentTokenId != _fromTokenId");
        address rootOwner = address(uint160(uint256(rootOwnerOf(_tokenId))));
        address approvedAddress =
            rootOwnerAndTokenIdToApprovedAddress[rootOwner][_tokenId];
        require(
            rootOwner == msg.sender ||
                tokenOwnerToOperators[rootOwner][msg.sender] ||
                approvedAddress == msg.sender,
                "ComposableBottomUp: transferAsChild msg.sender not eligible"
        );
        // clear approval
        if (approvedAddress != address(0)) {
            delete rootOwnerAndTokenIdToApprovedAddress[rootOwner][_tokenId];
            emit Approval(rootOwner, address(0), _tokenId);
        }

        // remove and transfer token
        if (_fromContract != _toContract) {
            assert(tokenOwnerToTokenCount[_fromContract] > 0);
            tokenOwnerToTokenCount[_fromContract]--;
            tokenOwnerToTokenCount[_toContract]++;
        }

        TokenOwner memory parentToken = TokenOwner(_toContract, _toTokenId);
        tokenIdToTokenOwner[_tokenId] = parentToken;

        removeChild(_fromContract, _fromTokenId, _tokenId);

        //add to parentToChildTokenIds
        uint256 index = parentToChildTokenIds[_toContract][_toTokenId].length;
        parentToChildTokenIds[_toContract][_toTokenId].push(_tokenId);
        tokenIdToChildTokenIdsIndex[_tokenId] = index;

        require(
            IERC721(_toContract).ownerOf(_toTokenId) != address(0),
            "ComposableBottomUp: transferAsChild _toTokenId does not exist"
        );

        emit Transfer(_fromContract, _toContract, _tokenId);
        emit TransferFromParent(_fromContract, _fromTokenId, _tokenId);
        emit TransferToParent(_toContract, _toTokenId, _tokenId);
    }

    function _transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) private {
        require(_from != address(0), "ComposableBottomUp: _transferFrom _from zero address");
        require(tokenIdToTokenOwner[_tokenId].tokenOwner == _from, "ComposableBottomUp: _transferFrom tokenOwner != _from");
        require(
            tokenIdToTokenOwner[_tokenId].parentTokenId == 0,
            "ComposableBottomUp: _transferFrom Cannot transfer from address when owned by a token."
        );
        require(_to != address(0), "ComposableBottomUp: _transferFrom _to zero address");
        address approvedAddress =
            rootOwnerAndTokenIdToApprovedAddress[_from][_tokenId];
        if (msg.sender != _from) {
            // 0xed81cdda == rootOwnerOfChild(address,uint256)
            bytes memory callData =
                abi.encodeWithSelector(0xed81cdda, address(this), _tokenId);
            (bool callSuccess, bytes memory data) = _from.staticcall(callData);
            if (callSuccess == true) {
                bytes32 rootOwner;
                if (callSuccess) {
                    assembly {
                        rootOwner := mload(add(data, 0x20))
                    }
                }
                require(
                    rootOwner >> 224 != ERC998_MAGIC_VALUE,
                    "ComposableBottomUp: _transferFrom Token is child of other top down composable"
                );
            }
            require(
                tokenOwnerToOperators[_from][msg.sender] ||
                    approvedAddress == msg.sender,
                    "ComposableBottomUp: _transferFrom msg.sender not eligible"
            );
        }

        // clear approval
        if (approvedAddress != address(0)) {
            delete rootOwnerAndTokenIdToApprovedAddress[_from][_tokenId];
            emit Approval(_from, address(0), _tokenId);
        }

        // remove and transfer token
        if (_from != _to) {
            assert(tokenOwnerToTokenCount[_from] > 0);
            tokenOwnerToTokenCount[_from]--;
            tokenIdToTokenOwner[_tokenId].tokenOwner = _to;
            tokenOwnerToTokenCount[_to]++;
        }
        emit Transfer(_from, _to, _tokenId);
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external override {
        _transferFrom(_from, _to, _tokenId);
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external override {
        _transferFrom(_from, _to, _tokenId);
        if (isContract(_to)) {
            bytes4 retval =
                IERC721Receiver(_to).onERC721Received(
                    msg.sender,
                    _from,
                    _tokenId,
                    ""
                );
            require(retval == ERC721_RECEIVED, "ComposableBottomUp: safeTransferFrom(3) onERC721Received invalid value");
        }
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) external override {
        _transferFrom(_from, _to, _tokenId);
        if (isContract(_to)) {
            bytes4 retval =
                IERC721Receiver(_to).onERC721Received(
                    msg.sender,
                    _from,
                    _tokenId,
                    _data
                );
            require(retval == ERC721_RECEIVED, "ComposableBottomUp: safeTransferFrom(4) onERC721Received invalid value");
        }
    }

    function totalChildTokens(address _parentContract, uint256 _parentTokenId)
        external
        view
        override
        returns (uint256)
    {
        return parentToChildTokenIds[_parentContract][_parentTokenId].length;
    }

    function childTokenByIndex(
        address _parentContract,
        uint256 _parentTokenId,
        uint256 _index
    ) external view override returns (uint256) {
        require(
            parentToChildTokenIds[_parentContract][_parentTokenId].length >
                _index,
                "ComposableBottomUp: childTokenByIndex invalid _index"
        );
        return parentToChildTokenIds[_parentContract][_parentTokenId][_index];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IERC998ERC721BottomUp {
    event TransferToParent(
        address indexed _toContract,
        uint256 indexed _toTokenId,
        uint256 _tokenId
    );
    event TransferFromParent(
        address indexed _fromContract,
        uint256 indexed _fromTokenId,
        uint256 _tokenId
    );

    function rootOwnerOf(uint256 _tokenId)
        external
        view
        returns (bytes32 rootOwner);

    /**
     * The tokenOwnerOf function gets the owner of the _tokenId which can be a user address or another ERC721 token.
     * The tokenOwner address return value can be either a user address or an ERC721 contract address.
     * If the tokenOwner address is a user address then parentTokenId will be 0 and should not be used or considered.
     * If tokenOwner address is a user address then isParent is false, otherwise isChild is true, which means that
     * tokenOwner is an ERC721 contract address and _tokenId is a child of tokenOwner and parentTokenId.
     */
    function tokenOwnerOf(uint256 _tokenId)
        external
        view
        returns (
            bytes32 tokenOwner,
            uint256 parentTokenId,
            bool isParent
        );

    // Transfers _tokenId as a child to _toContract and _toTokenId
    function transferToParent(
        address _from,
        address _toContract,
        uint256 _toTokenId,
        uint256 _tokenId,
        bytes memory _data
    ) external;

    // Transfers _tokenId from a parent ERC721 token to a user address.
    function transferFromParent(
        address _fromContract,
        uint256 _fromTokenId,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) external;

    // Transfers _tokenId from a parent ERC721 token to a parent ERC721 token.
    function transferAsChild(
        address _fromContract,
        uint256 _fromTokenId,
        address _toContract,
        uint256 _toTokenId,
        uint256 _tokenId,
        bytes memory _data
    ) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IERC998ERC721BottomUpEnumerable {
    function totalChildTokens(address _parentContract, uint256 _parentTokenId)
        external
        view
        returns (uint256);

    function childTokenByIndex(
        address _parentContract,
        uint256 _parentTokenId,
        uint256 _index
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}