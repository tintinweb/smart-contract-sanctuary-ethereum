/**
 *Submitted for verification at Etherscan.io on 2023-05-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract aboutMe {

    address public owner; // field 0

    struct Me {
        string name;
        string age;
        string nationality;
        string about;
        string blockchainCertificates;
        string contact;
    }
    
    struct MyChessGambit {
        string name;
        string description;
        string pgn;
    } 

    Me public me; // field 1
    MyChessGambit public myChessGambit; // field 2

    constructor() {
        owner = msg.sender;

        me = Me(
            "Amin Nasseri",
            "21",
            "Iranian",
            "I have over two years worth of experience in the field of blockchain, with five certificates from blockchain-council. To date, I have helped with five university thesis articles related to blockchain and I have done over 20 projects in the same field. Contact me for any further queries regarding Blockchain, Smart Contracts or NFTs...",
            "Certified Blockchain Expert, Certified Smart Contract Developer, Certified NFT Expert, Certified NFT Developer and Certified Cryptocurrency Trader",
            "[email protected]"
        );

        myChessGambit = MyChessGambit(
            "Amin's Gambit",
            "This gambit is so much fun, in a nutshell, you can mate your opponent using a pawn and a bishop in just 10 moves!",
            '[Event "?"][Site "?"][Date "????.??.??"][Round "?"][White "?"][Black "?"][Result "1-0"]1. e4 b6 2. Bc4 Bb7 3. Nc3 g6 4. d3 Bg7 5. h4 Nc6 6. Bg5 h6 7. h5 hxg5 8. hxg6Rxh1 9. gxf7+ Kf8 10. fxg8=R# 1-0'
        );
    }

    function changeData(
        uint8 fieldToChange, 
        address newOwner,
        Me memory _me, 
        MyChessGambit memory _myChessGambit
    ) 
        public returns (bool)
    {
        require(msg.sender == owner, "Only the owner can change data");

        if (fieldToChange == 0) {
            owner = newOwner;
        } else if (fieldToChange == 1) {
            me = _me;
        } else {
            myChessGambit = _myChessGambit;
        }

        return true;
    }

    function widthdraw(
        bool transferEthers, 
        address payable token, 
        bytes memory _data
    ) 
        public payable returns (bool success) 
    {
        require(msg.sender == owner, "Only the owner can widthdraw ethers");
        
        if (transferEthers) {
            uint256 val = address(this).balance;
            (success, ) = payable(owner).call{value: val}("");
            require(success, "Transfer of ethers will fail for unknown reason");
        } else {
            (success, ) = token.call{value: msg.value}(_data);
            require(success, "Transfer of tokens will fail for unknown reason");
        }
    }

    receive() external payable {}
}