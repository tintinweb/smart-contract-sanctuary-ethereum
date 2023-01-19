// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

// File: openzeppelin-solidity/contracts/token/ERC721/ERC721Receiver.sol

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 *  from ERC721 asset contracts.
 */
abstract contract LegacyERC721Receiver {
    /**
     * @dev Magic value to be returned upon successful reception of an NFT
     *  Equals to `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`,
     *  which can be also obtained as `ERC721Receiver(0).onERC721Received.selector`
     */
    bytes4 public constant ERC721_RECEIVED = 0xf0b9e5ba;

    /**
     * @notice Handle the receipt of an NFT
     * @dev The ERC721 smart contract calls this function on the recipient
     *  after a `safetransfer`. This function MAY throw to revert and reject the
     *  transfer. This function MUST use 50,000 gas or less. Return of other
     *  than the magic value MUST result in the transaction being reverted.
     *  Note: the contract address is always the message sender.
     * @param _from The sending address
     * @param _tokenId The NFT identifier which is being transfered
     * @param _data Additional data with no specified format
     * @return `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`
     */
    function onERC721Received(
        address _from,
        uint256 _tokenId,
        bytes memory _data
    ) public virtual returns (bytes4);
}

contract LegacyERC721BasicToken {
    using SafeMath for uint256;
    using AddressUtils for address;

    // Equals to `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`
    // which can be also obtained as `ERC721Receiver(0).onERC721Received.selector`
    bytes4 public constant ERC721_RECEIVED = 0xf0b9e5ba;

    // Mapping from token ID to owner
    mapping(uint256 => address) internal tokenOwner;

    // Mapping from token ID to approved address
    mapping(uint256 => address) internal tokenApprovals;

    // Mapping from owner to number of owned token
    mapping(address => uint256) internal ownedTokensCount;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) internal operatorApprovals;

    /**
     * @dev Guarantees msg.sender is owner of the given token
     * @param _tokenId uint256 ID of the token to validate its ownership belongs to msg.sender
     */
    modifier onlyOwnerOf(uint256 _tokenId) {
        require(ownerOf(_tokenId) == msg.sender, "onlyOwnerOf");
        _;
    }

    /**
     * @dev Checks msg.sender can transfer a token, by being owner, approved, or operator
     * @param _tokenId uint256 ID of the token to validate
     */
    modifier canTransfer(uint256 _tokenId) {
        require(isApprovedOrOwner(msg.sender, _tokenId), "canTransfer");
        _;
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /**
     * @dev Gets the balance of the specified address
     * @param _owner address to query the balance of
     * @return uint256 representing the amount owned by the passed address
     */
    function balanceOf(address _owner) public view returns (uint256) {
        require(_owner != address(0), "0 address");
        return ownedTokensCount[_owner];
    }

    /**
     * @dev Gets the owner of the specified token ID
     * @param _tokenId uint256 ID of the token to query the owner of
     * @return owner address currently marked as the owner of the given token ID
     */
    function ownerOf(uint256 _tokenId) public view returns (address) {
        address owner = tokenOwner[_tokenId];
        require(owner != address(0), "0 address");
        return owner;
    }

    /**
     * @dev Returns whether the specified token exists
     * @param _tokenId uint256 ID of the token to query the existance of
     * @return whether the token exists
     */
    function exists(uint256 _tokenId) public view returns (bool) {
        address owner = tokenOwner[_tokenId];
        return owner != address(0);
    }

    /**
     * @dev Approves another address to transfer the given token ID
     * @dev The zero address indicates there is no approved address.
     * @dev There can only be one approved address per token at a given time.
     * @dev Can only be called by the token owner or an approved operator.
     * @param _to address to be approved for the given token ID
     * @param _tokenId uint256 ID of the token to be approved
     */
    function approve(address _to, uint256 _tokenId) public {
        address owner = ownerOf(_tokenId);
        require(_to != owner, "same owner");
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "sender not owner");

        if (getApproved(_tokenId) != address(0) || _to != address(0)) {
            tokenApprovals[_tokenId] = _to;
            emit Approval(owner, _to, _tokenId);
        }
    }

    /**
     * @dev Gets the approved address for a token ID, or zero if no address set
     * @param _tokenId uint256 ID of the token to query the approval of
     * @return address currently approved for a the given token ID
     */
    function getApproved(uint256 _tokenId) public view returns (address) {
        return tokenApprovals[_tokenId];
    }

    /**
     * @dev Sets or unsets the approval of a given operator
     * @dev An operator is allowed to transfer all tokens of the sender on their behalf
     * @param _to operator address to set the approval
     * @param _approved representing the status of the approval to be set
     */
    function setApprovalForAll(address _to, bool _approved) public {
        require(_to != msg.sender, "to sender");
        operatorApprovals[msg.sender][_to] = _approved;
        emit ApprovalForAll(msg.sender, _to, _approved);
    }

    /**
     * @dev Tells whether an operator is approved by a given owner
     * @param _owner owner address which you want to query the approval of
     * @param _operator operator address which you want to query the approval of
     * @return bool whether the given operator is approved by the given owner
     */
    function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
        return operatorApprovals[_owner][_operator];
    }

    /**
     * @dev Transfers the ownership of a given token ID to another address
     * @dev Usage of this method is discouraged, use `safeTransferFrom` whenever possible
     * @dev Requires the msg sender to be the owner, approved, or operator
     * @param _from current owner of the token
     * @param _to address to receive the ownership of the given token ID
     * @param _tokenId uint256 ID of the token to be transferred
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public canTransfer(_tokenId) {
        require(_from != address(0), "from 0 address");
        require(_to != address(0), "to 0 address");

        clearApproval(_from, _tokenId);
        removeTokenFrom(_from, _tokenId);
        addTokenTo(_to, _tokenId);

        emit Transfer(_from, _to, _tokenId);
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * @dev If the target address is a contract, it must implement `onERC721Received`,
     *  which is called upon a safe transfer, and return the magic value
     *  `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`; otherwise,
     *  the transfer is reverted.
     * @dev Requires the msg sender to be the owner, approved, or operator
     * @param _from current owner of the token
     * @param _to address to receive the ownership of the given token ID
     * @param _tokenId uint256 ID of the token to be transferred
     */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public canTransfer(_tokenId) {
        // solium-disable-next-line arg-overflow
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * @dev If the target address is a contract, it must implement `onERC721Received`,
     *  which is called upon a safe transfer, and return the magic value
     *  `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`; otherwise,
     *  the transfer is reverted.
     * @dev Requires the msg sender to be the owner, approved, or operator
     * @param _from current owner of the token
     * @param _to address to receive the ownership of the given token ID
     * @param _tokenId uint256 ID of the token to be transferred
     * @param _data bytes data to send along with a safe transfer check
     */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) public canTransfer(_tokenId) {
        transferFrom(_from, _to, _tokenId);
        // solium-disable-next-line arg-overflow
        require(checkAndCallSafeTransfer(_from, _to, _tokenId, _data), "safe transfer failed");
    }

    /**
     * @dev Returns whether the given spender can transfer a given token ID
     * @param _spender address of the spender to query
     * @param _tokenId uint256 ID of the token to be transferred
     * @return bool whether the msg.sender is approved for the given token ID,
     *  is an operator of the owner, or is the owner of the token
     */
    function isApprovedOrOwner(address _spender, uint256 _tokenId) internal view returns (bool) {
        address owner = ownerOf(_tokenId);
        return _spender == owner || getApproved(_tokenId) == _spender || isApprovedForAll(owner, _spender);
    }

    /**
     * @dev Internal function to mint a new token
     * @dev Reverts if the given token ID already exists
     * @param _to The address that will own the minted token
     * @param _tokenId uint256 ID of the token to be minted by the msg.sender
     */
    function _mint(address _to, uint256 _tokenId) internal virtual {
        require(_to != address(0), "to 0 address");
        addTokenTo(_to, _tokenId);
        emit Transfer(address(0), _to, _tokenId);
    }

    /**
     * @dev Internal function to burn a specific token
     * @dev Reverts if the token does not exist
     * @param _tokenId uint256 ID of the token being burned by the msg.sender
     */
    function _burn(address _owner, uint256 _tokenId) internal virtual {
        clearApproval(_owner, _tokenId);
        removeTokenFrom(_owner, _tokenId);
        emit Transfer(_owner, address(0), _tokenId);
    }

    /**
     * @dev Internal function to clear current approval of a given token ID
     * @dev Reverts if the given address is not indeed the owner of the token
     * @param _owner owner of the token
     * @param _tokenId uint256 ID of the token to be transferred
     */
    function clearApproval(address _owner, uint256 _tokenId) internal {
        require(ownerOf(_tokenId) == _owner, "address not owner");
        if (tokenApprovals[_tokenId] != address(0)) {
            tokenApprovals[_tokenId] = address(0);
            emit Approval(_owner, address(0), _tokenId);
        }
    }

    /**
     * @dev Internal function to add a token ID to the list of a given address
     * @param _to address representing the new owner of the given token ID
     * @param _tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function addTokenTo(address _to, uint256 _tokenId) internal virtual {
        require(tokenOwner[_tokenId] == address(0), "already owner of token");
        tokenOwner[_tokenId] = _to;
        ownedTokensCount[_to] = ownedTokensCount[_to].add(1);
    }

    /**
     * @dev Internal function to remove a token ID from the list of a given address
     * @param _from address representing the previous owner of the given token ID
     * @param _tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function removeTokenFrom(address _from, uint256 _tokenId) internal virtual {
        require(ownerOf(_tokenId) == _from, "address not owner");
        ownedTokensCount[_from] = ownedTokensCount[_from].sub(1);
        tokenOwner[_tokenId] = address(0);
    }

    /**
     * @dev Internal function to invoke `onERC721Received` on a target address
     * @dev The call is not executed if the target address is not a contract
     * @param _from address representing the previous owner of the given token ID
     * @param _to target address that will receive the tokens
     * @param _tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return whether the call correctly returned the expected magic value
     */
    function checkAndCallSafeTransfer(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) internal returns (bool) {
        if (!_to.isContract()) {
            return true;
        }
        bytes4 retval = LegacyERC721Receiver(_to).onERC721Received(_from, _tokenId, _data);
        return (retval == ERC721_RECEIVED);
    }
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    /**
     * @dev Multiplies two numbers, throws on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
     * @dev Integer division of two numbers, truncating the quotient.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }

    /**
     * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
     * @dev Adds two numbers, throws on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

/**
 * Utility library of inline functions on addresses
 */
library AddressUtils {
    /**
     * Returns whether the target address is a contract
     * @dev This function will return false if invoked during the constructor of a contract,
     *  as the code is not actually created until after the constructor finishes.
     * @param addr address to check
     * @return whether the target address is a contract
     */
    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        // XXX Currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(addr)
        } // solium-disable-line security/no-inline-assembly
        return size > 0;
    }
}

contract TestLegacyERC721 is LegacyERC721BasicToken {
    uint256 public tokenId;

    string public constant name = "TestLegacyERC721";
    string public constant symbol = "TLT";

    function mint(address _to) public {
        _mint(_to, tokenId);
        tokenId++;
    }

    function mintToSender() public {
        _mint(msg.sender, tokenId);
        tokenId++;
    }
}