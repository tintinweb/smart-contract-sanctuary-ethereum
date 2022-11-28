/**
 *Submitted for verification at Etherscan.io on 2022-11-28
*/

pragma solidity ^0.8.14;

interface ERC20 {
    function transfer(address _to, uint256 _value) external returns (bool);
    function balanceOf(address guy) external view returns (uint);
}

contract Merchant {
    address platform;
    address merchant;

    mapping(string => uint256) fees;
    mapping(string => address) addr;
    address owner;

    constructor() {
        init();
    }

    modifier onlyOwner () {
        require(
            msg.sender == owner,
            "Only own can call this."
        );
        _;
    }

    event Withdraw(uint256 amount, address token);
    event Destroy(address merchant, address sender);
    event Received(address, uint);
    event WithdrawAmount(uint256 amount, string currency);

    // When there is no matching function to call in the contract, call the fallback function
    fallback() external payable {}
    // Receive and forward ether via contracts
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    // Initialize internal variables
    function init() internal {
        platform = 0x5930DddCbDa212cf2ED3511EA2fDA9ccd66E0b30;
        merchant = 0x82fC0c4a8071fc75497B7f47f1d8B8053251a29c;

        fees["USDT"] = 800;
        fees["USDC"] = 800;
        fees["DAI"] = 800;
        fees["ETH"] = 800;
        fees["SHIB"] = 800;

        addr["USDT"] = 0xbF14b63FF0DD15aDe35C3A1b70412EB92A81769C;
        addr["USDC"] = 0x1021138E0Ba21a3F2951002bEE0411D545D13FA4;
        addr["ETH"] = address(0);
        addr["DAI"] = 0x51A1Dd8E5d2413ada0F1ed4d469B246d22dE7F50;
        addr["SHIB"] = 0xEca5fa2B92a9F2CAf351BF44921Ab81Fb2Bea36b;

        owner = msg.sender;
    }

    // destroy this contract.
    function destroy() public onlyOwner {
        selfdestruct(payable(address(this)));
        emit Destroy(merchant, msg.sender);
    }

    // get the token balance according to the token contract
    function balance(address _token) public view onlyOwner returns (uint) {
        uint amount;
        if(_token == address(0)){
            amount = address(this).balance;
        }else{
            amount = ERC20(_token).balanceOf(address(this));
        }
        return amount;
    }

    // withdraw currencies
    function withdraw(address erc20Token, string memory currency, uint amount, uint transtion, address _tokenContract) public onlyOwner payable {
        ERC20 _token = ERC20(erc20Token);

        uint fee;
        uint available;
        if(_tokenContract == erc20Token){
            fee = (amount * fees[currency] / 100000) + transtion;
            available = amount - fee - transtion;
        }else{
            fee = amount * fees[currency] / 100000;
            available = amount - fee;
        }

        if(erc20Token == address(0)) {
            payable(platform).transfer(fee);
            payable(merchant).transfer(available);
        }else{
            _token.transfer(merchant, available);
            _token.transfer(platform, fee);
        }
    }

    // Allot all tokens.
    function withdrawAllTokens(uint transtion, address _tokenContract) public onlyOwner {
        string[5] memory _tokens = ["ETH", "USDC", "USDT", "DAI", "SHIB"];
        uint8 i = 0;
        for (i; i < _tokens.length; i++) {
            ERC20 _token = ERC20(addr[_tokens[i]]);
            uint amount;
            if(addr[_tokens[i]] == address(0)){
                amount = address(this).balance;
            }else{
                amount = _token.balanceOf(address(this));
            }
            if(amount == 0) continue;

            withdraw(addr[_tokens[i]], _tokens[i], amount, transtion, _tokenContract);
        }
    }
}