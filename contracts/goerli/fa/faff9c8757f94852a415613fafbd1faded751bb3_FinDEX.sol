/**
 *Submitted for verification at Etherscan.io on 2022-11-26
*/

// SPDX-License-Identifier: CC-BY-ND-4.0

pragma solidity ^0.8.17;

contract protected {
    mapping (address => bool) is_auth;
    function authorized(address addy) public view returns(bool) {
        return is_auth[addy];
    }
    function set_authorized(address addy, bool booly) public onlyAuth {
        is_auth[addy] = booly;
    }
    modifier onlyAuth() {
        require( is_auth[msg.sender] || msg.sender==owner, "not owner");
        _;
    }
    address owner;
    modifier onlyOwner() {
        require(msg.sender==owner, "not owner");
        _;
    }
    bool locked;
    modifier safe() {
        require(!locked, "reentrant");
        locked = true;
        _;
        locked = false;
    }
    function change_owner(address new_owner) public onlyAuth {
        owner = new_owner;
    }
    receive() external payable {}
    fallback() external payable {}
}

interface IERC20 {

    /// @param _owner The address from which the balance will be retrieved
    /// @return balance the balance
    function balanceOf(address _owner) external view returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return success Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) external returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return success Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return success Whether the approval was successful or not
    function approve(address _spender, uint256 _value) external returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return remaining Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


interface ERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

interface ERC721 is ERC165 {
    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) external view returns (uint256);

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) external view returns (address);

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) external payable;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external payable;

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external;

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address);

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}


contract FinDEX is protected {

    struct ACCOUNT {
        mapping(address => uint) balances_erc20;
        mapping(address => mapping(uint => bool)) balances_erc721;
        mapping(address => uint[]) balances_erc721_array;
        mapping(address => mapping(uint => uint)) balances_erc721_index;
        uint native_balance;
        bool bePublic;
    }

    mapping(address => ACCOUNT) accounts;

    constructor() {
        owner = msg.sender;
        is_auth[msg.sender] = true;
    }

    // Deposits

    function deposit_erc20(address token, uint amount) public {
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        accounts[msg.sender].balances_erc20[token] += amount;
    }

    function deposit_erc721(address token, uint id) public {
        ERC721(token).transferFrom(msg.sender, address(this), id);
        accounts[msg.sender].balances_erc721_array[token].push(id);
        accounts[msg.sender].balances_erc721_index[token][id] = accounts[msg.sender].balances_erc721_array[token].length - 1;
        accounts[msg.sender].balances_erc721[token][id] = true;
    }

    function deposit_native() public payable {
        accounts[msg.sender].native_balance += msg.value;
    }

    // Withdraw

    function withdraw_erc20(address token, uint amount) public {
        require(accounts[msg.sender].balances_erc20[token] >= amount, "Insufficient balance");
        accounts[msg.sender].balances_erc20[token] -= amount;
        IERC20(token).transfer(msg.sender, amount);
    }

    function withdraw_erc721(address token, uint id) public {
        require(accounts[msg.sender].balances_erc721[token][id], "Insufficient balance");
        uint _index = accounts[msg.sender].balances_erc721_index[token][id];
        uint _last = accounts[msg.sender].balances_erc721_array[token].length - 1;
        uint _last_id = accounts[msg.sender].balances_erc721_array[token][_last];
        accounts[msg.sender].balances_erc721_array[token][_index] = _last_id;
        accounts[msg.sender].balances_erc721_index[token][_last_id] = _index;
        accounts[msg.sender].balances_erc721_array[token][_last] = id;
        delete accounts[msg.sender].balances_erc721_array[token][_last];
        accounts[msg.sender].balances_erc721[token][id] = false;
        ERC721(token).transferFrom(address(this), msg.sender, id);
    }

    function withdraw_native(uint amount) public {
        require(accounts[msg.sender].native_balance >= amount, "Insufficient balance");
        accounts[msg.sender].native_balance -= amount;
        payable(msg.sender).transfer(amount);
    }

    // Transfers

    function transfer_erc20(address token, uint amount, address to) public {
        require(accounts[msg.sender].balances_erc20[token] >= amount, "Insufficient balance");
        accounts[msg.sender].balances_erc20[token] -= amount;
        accounts[to].balances_erc20[token] += amount;
    }

    function transfer_erc721(address token, uint id, address to) public {
        require(accounts[msg.sender].balances_erc721[token][id], "Insufficient balance");
        uint _index = accounts[msg.sender].balances_erc721_index[token][id];
        uint _last = accounts[msg.sender].balances_erc721_array[token].length - 1;
        uint _last_id = accounts[msg.sender].balances_erc721_array[token][_last];
        accounts[msg.sender].balances_erc721_array[token][_index] = _last_id;
        accounts[msg.sender].balances_erc721_index[token][_last_id] = _index;
        accounts[msg.sender].balances_erc721_array[token][_last] = id;
        delete accounts[msg.sender].balances_erc721_array[token][_last];
        accounts[msg.sender].balances_erc721[token][id] = false;
        accounts[to].balances_erc721_array[token].push(id);
        accounts[to].balances_erc721_index[token][id] = accounts[to].balances_erc721_array[token].length - 1;
        accounts[to].balances_erc721[token][id] = true;
    }

    function transfer_native(uint amount, address to) public {
        require(accounts[msg.sender].native_balance >= amount, "Insufficient balance");
        accounts[msg.sender].native_balance -= amount;
        accounts[to].native_balance += amount;
    }

    // Reads

    function get_erc20_balance(address token) public view returns (uint) {
        return accounts[msg.sender].balances_erc20[token];
    }

    function get_erc721_owned(address token, uint id) public view returns (bool) {
        return accounts[msg.sender].balances_erc721[token][id];
    }

    function get_erc721_balance(address token) public view returns (uint, uint[] memory) {
        return (accounts[msg.sender].balances_erc721_array[token].length,
                accounts[msg.sender].balances_erc721_array[token]);
    }

    function get_native_balance() public view returns (uint) {
        return accounts[msg.sender].native_balance;
    }

    // Controls

    function set_public(bool bePublic) public {
        accounts[msg.sender].bePublic = bePublic;
    }
}