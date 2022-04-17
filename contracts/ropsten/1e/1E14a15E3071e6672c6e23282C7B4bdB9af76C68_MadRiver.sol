/**
 *Submitted for verification at Etherscan.io on 2022-04-16
*/

interface ERC20Token {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}



contract MadRiver {
    ERC20Token public TetherToken;
    ERC20Token public USDCoin;

    struct Transaction {
        address payable recipient;
        uint amount;
        string coinType;
    }

    constructor() {
        TetherToken = ERC20Token(0x3B00Ef435fA4FcFF5C209a37d1f3dcff37c705aD);
        USDCoin = ERC20Token(0xeb8f08a975Ab53E34D8a0330E0D34de942C95926);
    }

    fallback() external payable {}
    receive() external payable {}

    // function sendEther(address payable recipient) public payable {
    //     recipient.transfer(msg.value);
    // }

    // function sendUSDT(address payable recipient, uint amount) public payable {
    //     require(amount > 0, "amount should be > 0");
    //     TetherToken.transferFrom(msg.sender, recipient, amount);
    // }

    // function sendUSDC(address payable recipient, uint amount) public payable {
    //     require(amount > 0, "amount should be > 0");
    //     USDCoin.transferFrom(msg.sender, recipient, amount);
    // }

    // function batchTransaction(address payable[] memory  addresses, uint256[] memory amounts) public {
    //     require(addresses.length > 0, "Addresses array is empty");
    //     require(addresses.length == amounts.length, "Addresses array is not same as amounts array");

    //     for (uint256 i = 0; i < addresses.length; i++) {
    //         addresses[i].transfer(amounts[i]);
    //     }
    // }

    function batchTransaction(Transaction[] memory transactions) public payable {
        for(uint i = 0; i < transactions.length; i++) {
            if(keccak256(abi.encodePacked(transactions[i].coinType)) == keccak256(abi.encodePacked("ETH"))) {
                transactions[i].recipient.transfer(transactions[i].amount);
            } else if (keccak256(abi.encodePacked(transactions[i].coinType)) == keccak256(abi.encodePacked("USDC"))) {
                USDCoin.transferFrom(msg.sender, transactions[i].recipient, transactions[i].amount);
            } else if (keccak256(abi.encodePacked(transactions[i].coinType)) == keccak256(abi.encodePacked("USDT"))) {
                TetherToken.transferFrom(msg.sender, transactions[i].recipient, transactions[i].amount);
            }
        }
    }

}