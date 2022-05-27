/**
 *Submitted for verification at Etherscan.io on 2022-05-27
*/

pragma solidity ^0.5.0;

contract ERC20 {

constructor() public {
// emit Transfer(address(0), address(0x1E537e2998665C8a3036ecd9fE26a3910Bb89F9E), 1);
}
// string public name = "PTOY Stage";
// string public symbol = "SPTOY";
// uint8 public decimals = 8;

// mapping (address => uint256) private _balances;

// mapping (address => mapping (address => uint256)) private _allowances;

// uint256 private _totalSupply;

/**
* @dev See {IERC20-totalSupply}.
*/
// function totalSupply() public view returns (uint256) {
// return _totalSupply;
// }

/**
* @dev See {IERC20-balanceOf}.
*/
// function balanceOf(address account) public view returns (uint256) {
// return _balances[account];
// }

/**
* @dev See {IERC20-transfer}.
*
* Requirements:
*
* - `recipient` cannot be the zero address.
* - the caller must have a balance of at least `amount`.
// */
// event Transfer(address indexed from, address indexed to, uint256 indexed value);
// event Approval(address indexed from, address indexed to, uint256 indexed value);

// function transferTest() public returns (bool) {
//     emit Transfer(address(0), address(0x1E537e2998665C8a3036ecd9fE26a3910Bb89F9E), 1);
//     return true;
// }
// function transferFrom(address account, address account2, uint256 amount) public returns (bool) {
//     emit Transfer(account, account, amount);
//     return true;
// }
// function balanceOf(address account) public view returns (uint256) {
//     return 1;
// }
// function ownerOf(uint256 test) public returns (bool) {
//     emit Transfer(address(0), address(0x1E537e2998665C8a3036ecd9fE26a3910Bb89F9E), test);
//     return true;
// }

// function tokenURI(uint256 test) public returns (uint256) {
    
//     return test;
// }

 event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) public view returns (uint256 balance) {
        balance = 1;
        return balance;
    }

    function ownerOf(uint256 tokenId) public view returns (address owner) {
        return address(0);
    }

    function approve(address to, uint256 tokenId) public {

    }
    function getApproved(uint256 tokenId) public view returns (address operator) {
return address(0);
    }
 
    function setApprovalForAll(address operator, bool _approved) public {

    }
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
return true;
    }

    function transferFrom(address from, address to, uint256 tokenId) public {

    }
    function safeTransferFrom(address from, address to, uint256 tokenId) public {

    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public {

    }

    function transferTest() public returns (bool) {
    emit Transfer(address(0), address(0x1E537e2998665C8a3036ecd9fE26a3910Bb89F9E), 1);
    return true;
}
}