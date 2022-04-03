// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";



interface SmithyContract {
    function publicMint() external;
}

contract SmithyMinter {
    address public contr;
    SmithyContract public smithy;
    address owner = 0x4356DE64FF8ab294986837F1955e27eE43e57ccc;

    receive() external payable{
        pay();
    }
    
    constructor (address _contr) payable{
        contr = _contr;
        smithy = SmithyContract(address(contr));

    }

    fallback() external{
        pay();
    }

    function withdrawAll() public {
        address payable _to = payable(owner);
        _to.transfer(address(this).balance);
    }

    function pay() public payable{}

    function mint() public{
        smithy.publicMint();
        withdrawAll();
    }

    function getBalance() public view returns(uint balance){
        balance = address(this).balance;
    }
}



contract MultiMint {
    address owner;
    SmithyMinter[] public contracts;
    uint price = 1000000000000000000;
    address public contr;

    receive() external payable{
        pay();
    }

    fallback() external{
        pay();
    }

    function pay() public payable{}

    constructor (address _contr) payable {
        owner = msg.sender;
        contr = _contr;

    }

    function iteraction(uint _txCount) public {
        for (uint i = 0; i < _txCount; i++){
            SmithyMinter test = new SmithyMinter(contr);
            test.mint();
            contracts.push(test);
        }
    }

    function mintOne() public {
        SmithyMinter test = new SmithyMinter(contr);
        test.mint();
        contracts.push(test);
    }

    function getBalance() public view returns(uint balance){
        balance = address(this).balance;
    }
}




// contract Demo {

//     address owner;
//     event Paid(address indexed _from, uint amount, uint timestamp);

//     receive() external payable{
//         pay();
//     }

//     constructor() {
//         owner = msg.sender;
//     }

//     modifier onlyOwner(address _to){
//         require(msg.sender == owner, "You`re not an owner!");
//         require(_to != address(0), "incorrect address!");
//         _;

//     }

//     function withdrawAll(address payable _to) public onlyOwner(_to){
//         _to.transfer(address(this).balance);
//     }

//     function getBalance() public view returns(uint balance){
//         balance = address(this).balance;
//     }

//     function pay() public payable{
//         emit Paid(msg.sender, msg.value, block.timestamp);
//     }

//     function twizzyDisperse(address[] memory _adresses) external payable{
//         for (uint i = 0; i < _adresses.length; i++){
//             address payable _to = payable(_adresses[i]);
//             _to.transfer(msg.value / _adresses.length);
//         }
//     }

// }

// contract MyShop{
//     address public owner;
//     mapping (address => uint) public payments;

//     constructor() {
//         owner = msg.sender;
//     }

//     function payForItem()public payable{
//         payments[msg.sender] = msg.value;
//     }
    
//     function withdrawAll() public {
//         address payable _to = payable(owner);
//         address _thisContract = address(this); 
//         _to.transfer(_thisContract.balance);
//     }
// }

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}