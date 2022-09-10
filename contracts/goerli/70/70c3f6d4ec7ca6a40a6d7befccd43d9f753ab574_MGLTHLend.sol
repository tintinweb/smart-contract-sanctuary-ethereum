//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.15;

import "solmate/auth/Owned.sol";

interface MGLTH {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function broadcast(uint token, string calldata mediaHash) external;
    function vandalize(uint token, string calldata mediaHash) external payable;
}

contract MGLTHLend is Owned {
    constructor()Owned(msg.sender){}
    
    address immutable mglthContract = 0x2874cC487988cbBC35Da9a3b5C406dDf44Ec17D8;
    mapping(uint => address) public depositor;
    mapping(uint => address) public borrower;
    
    event ProxyBroadcast(address indexed ProxyInjector, uint indexed token, string indexed mediaHash);
    event ProxyVandalize(address indexed ProxyInjector, uint indexed token, string indexed mediaHash);
    event Deposit(address indexed depositor, address indexed borrower, uint indexed tokenID);
    event Withdraw(address indexed depositor, uint indexed tokenID);


    function deposit(uint tokenID, address receiver) external {
        borrower[tokenID] = receiver;
        depositor[tokenID] = msg.sender;
        MGLTH(mglthContract).transferFrom(msg.sender, address(this), tokenID);
        emit Deposit(msg.sender, receiver, tokenID);
    }

    function proxyBroadcast(uint token, string memory mediaHash) external {
        require(borrower[token] == msg.sender, "MGLTHLend: Not your token");
        MGLTH(mglthContract).broadcast(token, mediaHash);
        emit ProxyBroadcast(msg.sender, token, mediaHash);
    }

    function proxyVandalize(uint token, string memory mediaHash) external payable {
        require(borrower[token] == msg.sender, "MGLTHLend: Not your token");
        MGLTH(mglthContract).vandalize{value: msg.value}(token, mediaHash);
        emit ProxyVandalize(msg.sender, token, mediaHash);   
    }

    function withdraw(uint tokenID) external {
        require(depositor[tokenID] == msg.sender, "You are not the depositor");
        MGLTH(mglthContract).transferFrom(address(this), msg.sender, tokenID);
        emit Withdraw(msg.sender, tokenID);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnerUpdated(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnerUpdated(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function setOwner(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}