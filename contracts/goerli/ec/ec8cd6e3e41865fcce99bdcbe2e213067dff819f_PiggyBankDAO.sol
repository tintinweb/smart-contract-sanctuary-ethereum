pragma solidity >=0.6.2;

/// @dev Interface of the ERC20 standard as defined in the EIP.
/// @dev This includes the optional name, symbol, and decimals metadata.
interface IERC20 {
    /// @dev Emitted when `value` tokens are moved from one account (`from`) to another (`to`).
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @dev Emitted when the allowance of a `spender` for an `owner` is set, where `value`
    /// is the new allowance.
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice Returns the amount of tokens in existence.
    function totalSupply() external view returns (uint256);

    /// @notice Returns the amount of tokens owned by `account`.
    function balanceOf(address account) external view returns (uint256);

    /// @notice Moves `amount` tokens from the caller's account to `to`.
    function transfer(address to, uint256 amount) external returns (bool);

    /// @notice Returns the remaining number of tokens that `spender` is allowed
    /// to spend on behalf of `owner`
    function allowance(address owner, address spender) external view returns (uint256);

    /// @notice Sets `amount` as the allowance of `spender` over the caller's tokens.
    /// @dev Be aware of front-running risks: https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    function approve(address spender, uint256 amount) external returns (bool);

    /// @notice Moves `amount` tokens from `from` to `to` using the allowance mechanism.
    /// `amount` is then deducted from the caller's allowance.
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    /// @notice Returns the name of the token.
    function name() external view returns (string memory);

    /// @notice Returns the symbol of the token.
    function symbol() external view returns (string memory);

    /// @notice Returns the decimals places of the token.
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import {IERC20} from "forge-std/interfaces/IERC20.sol";

contract PiggyBankDAO{

    uint256 daoCounter = 0;

    mapping (address => mapping(uint256 => bool)) isMember;

    mapping (uint256 => uint256) memberCount;

    mapping (uint256 => mapping(address => uint256)) transferredTotal;

    mapping (uint256 => mapping(address => mapping(address => uint256))) withdrawnTotal;

    mapping (uint256 => address[]) tokensList;

    mapping (address => uint256[]) memberOfList;

    error NoMembership();

    error IncorrectTokenAmount();

    error DAONotYetOpened();

    error NoMembersInList();

    error ZeroAddressNotAllowed();

    function counter() public view returns(uint256) {
        return daoCounter;
     }

    function memberOf() public view returns (uint256[] memory) {
        return memberOfList[msg.sender];
    }

    function balanceOf(uint256 id, address token) public view returns (uint256) {
        require(isMember[msg.sender][id], "none of your business");
        return transferredTotal[id][token];
    }

    function membersCount(uint256 id) public view returns (uint256){
        return memberCount[id];
    }

    function tokensListOf(uint256 id) public view returns (address[] memory) {
        return tokensList[id];
    }

    function tokensWithdrawn(uint256 id, address token) public view returns (uint256) {
        require(isMember[msg.sender][id], "none of your business");
        return withdrawnTotal[id][msg.sender][token];
    }

    function openDAO(address[] memory members) public returns (uint256){
        if (members.length == 0) {
            revert NoMembersInList();
        }
        uint256 newId = ++daoCounter;
        for (uint i = 0; i < members.length; i++) {
            isMember[members[i]][newId] = true;
            memberOfList[members[i]].push(newId);
        }
        if (isMember[address(0)][newId]) {
            revert ZeroAddressNotAllowed();
        }
        memberCount[newId] = members.length;
        return newId;
    }

    function transfer(uint256 id, uint256 amount, IERC20 token) public {
        if (id > daoCounter) {
            revert DAONotYetOpened();
        }
        token.transferFrom(msg.sender, address(this), amount);
        transferredTotal[id][address(token)] += amount;
        bool isNewToken = true;
        for (uint i = 0; i < tokensList[id].length; i++) {
            if (tokensList[id][i] == address(token)) {
                isNewToken = false;
                break;
            }
        }
        if (isNewToken) {
            tokensList[id].push(address(token));
        }
    }

    function withdraw(uint256 id, uint256 amount, IERC20 token, address receiver) public {
        if (id > daoCounter) {
            revert DAONotYetOpened();
        }
        if (!isMember[msg.sender][id]) {
            revert NoMembership();
        }
        if (receiver == address(0)) {
            revert ZeroAddressNotAllowed();
        }
        withdrawnTotal[id][msg.sender][address(token)] += amount;
        if (withdrawnTotal[id][msg.sender][address(token)] * memberCount[id] > transferredTotal[id][address(token)]) {
            revert IncorrectTokenAmount();
        }
        token.transfer(receiver, amount);
    }
}