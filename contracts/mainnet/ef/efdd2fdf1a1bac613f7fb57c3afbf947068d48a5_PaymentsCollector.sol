pragma solidity ^0.5.8;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

// TODO - Safe ERC20: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/SafeERC20.sol

contract PaymentsCollector is Ownable {

    address[] public tokens;
    address withdrawer;
    address payable acceptor;

    event EthPayment(address indexed buyer, uint256 indexed amount, string orderId);
    event TokenPayment(address indexed token, address indexed buyer, uint256 indexed amount, string orderId);

    constructor(address payable _acceptor) public {
        require(_acceptor != address(0), "PaymentsCollector: Acceptor Cannot Be Empty");
        acceptor = _acceptor;
    }

    // PAYMENTS

    function payEth(string memory _orderId) public payable {
        require(msg.value > 0, "PaymentsCollector: Cannot Pay 0 ETH");
        emit EthPayment(msg.sender, msg.value, _orderId);
    }

    function payToken(address _tokenAddr, uint256 _amount, string memory _orderId) public isWhitelisted(_tokenAddr) {
        require(_amount > 0, "PaymentsCollector: Cannot Pay 0 Tokens");

        IERC20 token = IERC20(_tokenAddr);
        SafeERC20.safeTransferFrom(token, msg.sender, address(this), _amount);

        emit TokenPayment(_tokenAddr, msg.sender, _amount, _orderId);
    }

    // WITHDRAWLS

    function withdrawEth() public onlyWithdrawer() {
        require(address(this).balance > 0, "PaymentsCollector: No Eth");
        acceptor.transfer(address(this).balance);
    }

    function withdrawToken(address _tokenAddr) public onlyWithdrawer() isWhitelisted(_tokenAddr) {
        IERC20 token = IERC20(_tokenAddr);
        uint256 balance = token.balanceOf(address(this));

        require(balance > 0, "PaymentsCollector: No Token Balance");

        SafeERC20.safeTransfer(token, acceptor, balance);
    }

    //  ADMINISTRATION

    function setWithdrawer(address _newWithdrawer) public onlyOwner() {
        withdrawer = _newWithdrawer;
    }

    function setAcceptor(address payable _newAcceptor) public onlyOwner() {
        require(acceptor != address(0), "PaymentsCollector: Acceptor Cannot Be Empty");
        acceptor = _newAcceptor;
    }

    function whitelist(address _tokenAddr) public onlyOwner() isNotWhitelisted(_tokenAddr) {
        tokens.push(_tokenAddr);
    }

    function delist(address _tokenAddr) public onlyOwner() {
        for(uint i = 0; i < tokens.length; i++) {

            if (tokens[i] == _tokenAddr) {
                if (i < (tokens.length - 1)) {
                    tokens[i] = tokens[tokens.length - 1];
                }

                tokens.length -= 1;
                return;
            }
        }

        require(false, "PaymentsCollector: Token Not Whitelisted");
    }

    // VIEWS

    function numTokens() public view returns(uint256) {
        return tokens.length;
    }

    // FALLBACK

    function() external payable {
        require(false, "PaymentsCollector: Cannot Pay Direct To Contract");
    }

    // MODIFIERS

    modifier isNotWhitelisted(address _tokenAddr) {
        for(uint i = 0; i < tokens.length; i++) {
            require(tokens[i] != _tokenAddr, "PaymentsCollector: Token Already Listed");
        }

        _;
    }

    modifier isWhitelisted(address _tokenAddr) {
        bool tokenFound = false;

        for(uint i = 0; i < tokens.length; i++) {
            if (tokens[i] == _tokenAddr) {
                tokenFound = true;
                break;
            }
        }

        require(tokenFound, "PaymentsCollector: Token Not Approved");
        _;
    }

    modifier onlyWithdrawer() {
        require(msg.sender == withdrawer, "PaymentsCollector: Not Withdrawer");
        _;
    }
}