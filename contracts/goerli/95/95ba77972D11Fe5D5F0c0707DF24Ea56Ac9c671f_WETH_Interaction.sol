/**
 *Submitted for verification at Etherscan.io on 2023-02-16
*/

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

contract WETH_Interaction {

    address wethAddress; //WETH address
   // address payable wethAddressPayable = payable(0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6); //The payable WETH address
    IERC20_WETH wethInterface; //WETH interface

    address operator; //The vault's operator
    address newOperator; //A variable used for safer transitioning between vault operators

    constructor() {

        operator = msg.sender;

        wethAddress = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;//set this to be the vault's asset address
        wethInterface = IERC20_WETH(wethAddress); //this initializes an interface with the asset 
    }

    modifier onlyOperator() {
        require(msg.sender == operator, "You aren't the operator.");
        _;
    }

    function showBalance() public view returns(uint){
        return address(this).balance;
    }

        //wethInterface.deposit{value: address(this).balance};

    function deposit() public payable onlyOperator 
    {
        payable(wethAddress).transfer(msg.value);
    }

    function deposit2() public payable onlyOperator 
    {
      (bool success, bytes memory data) = payable(wethAddress).call{value: msg.value}("");
    }

    function deposit3() public payable onlyOperator
    {
        wethInterface.deposit{value: msg.value};
    }

    function deposit4() public payable onlyOperator
    {
         wethInterface.deposit{value: msg.value}();
    }

  /* function deposit3() public payable onlyOperator 
    {
        wethAddressPayable.transfer(msg.value);
    }
*/


    function withdraw() public onlyOperator {
        uint256 bal = wethInterface.balanceOf(address(this));

        wethInterface.approve(wethAddress, bal);//Approve the WETH contract to approve this balance

        wethInterface.withdraw(bal); //Unwrap assets - WETH into ETH - 
        //The asset from the vault is WETH...so we call withdraw on the asset Interface to get raw ETH
    }

    fallback() external payable {}
    receive() external payable {}

}


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20_WETH {

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    
    //WETH Deposit function
    //Had this as external and not public - fixed?
    function deposit() external payable ;

    //WETH Withdraw function
    //I had this as uint256 instead of uint
    //I also had it as external and not public - fixed?
    function withdraw(uint amt) external ; 

}