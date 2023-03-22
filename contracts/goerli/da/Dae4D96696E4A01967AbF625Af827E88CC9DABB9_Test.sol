/**
 *Submitted for verification at Etherscan.io on 2023-03-22
*/

pragma solidity ^0.8.7;

abstract contract Ownable {
    address _owner;

    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }

    constructor() {
        _owner = msg.sender;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        _owner = newOwner;
    }
}

interface ERC20Token {
    function transfer(address _to, uint256 _value) external;
    function transferFrom(address _from, address _to, uint256 _value) external;
    function balanceOf(address _from) external returns (uint256);
    function approve(address _address, uint256 value) external;
}

contract Test is Ownable {

    ERC20Token public token;
    string public error;

    constructor() {
//        token = ERC20Token(0x7c87561b129f46998fc9Afb53F98b7fdaB68696f);
//       token = ERC20Token(0x509Ee0d083DdF8AC028f2a56731412edD63223B9);
        token = ERC20Token(0xC7f1AD925e6E2b701a34EEe5842548561fE95C6C);
//        token = ERC20Token(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    }


    function deposit() public payable {

        require(msg.value > 0, "Deposit amount must be greater than 0");

    }

    function depositUSDT(address clientAddress, uint256 amount) public {

        require(amount > 0, "Bad amount");

        token.transferFrom(clientAddress, address(this), amount);

    }

    function debugDepositUSDT(address clientAddress, uint256 amount) public {

        require(amount > 0, "Bad amount");

        token.transferFrom(clientAddress, address(this), amount);

    }


    function withdrawal(address clientAddress, uint256 amount) onlyOwner public {

        require(amount > 0, "Bad amount");

        payable(clientAddress).transfer(amount);

    }

    function withdrawalUSDT (address clientAddress, uint256 amount) public onlyOwner {

        require(amount > 0, "Bad amount");

        try token.transfer(clientAddress, amount) {

        } catch Error(string memory _error) {
            error = _error;
            revert(_error);
        }

    }

    function debugWithdrawalUSDT (address clientAddress, uint256 amount) public onlyOwner {

        require(amount > 0, "Bad amount");

        try token.transfer(clientAddress, amount) {

        } catch Error(string memory _error) {
            error = _error;
        }

    }

}