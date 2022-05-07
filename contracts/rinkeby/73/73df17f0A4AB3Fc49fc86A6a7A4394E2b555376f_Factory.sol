// SPDX-License-Identifier: MIT
// compiler version must be greater than or equal to 0.8.10 and less than 0.9.0
// CREATED BY RIPLE <3
// THIS CONTRACT MANAGE ALL ECOSYSTEM OF UnNFT's CONTRACTS
pragma solidity ^0.8.4;

import "./NFT.sol";

contract Factory {

    // fallback() external payable {}              // Make contract payable
    receive() external payable {}               // Make contract payable
    event ContractCreated(address newAddress);  // For returning address of NFT
    mapping(string => bool) internal Links;     // Mapping for checking unique url
    mapping(uint => address) internal devList;  // List of developers, any dev have a own code number
    address[] internal nftAddressStore;         // array of all nfts
    address private adminAddress;               // address of Contract Creator 

    constructor(address _admin) {
        adminAddress =  _admin;
    }

    // CREATE NEW NFT
    function Mint(string memory _link) external {
        require(Links[_link] == false, "You can't create this NFT!");
        UnNFT nft = new UnNFT(_link, nftAddressStore.length, msg.sender);
        Links[_link] = true;                    // make this url imposible to use
        nftAddressStore.push(address(nft));     // add to array new nft
        emit ContractCreated(address(nft));
    }

    // NFT'S ADDRESS BY NUMBER OF MINT
    function tokenID(uint _number) external view returns(address) {
        return nftAddressStore[_number];
    }
    // TOTAL SUPPLY NFTS
    function totalValueNFTs() external view returns(uint) {
        return nftAddressStore.length;          // returns length of array
    }

    // FOR NFTS DATA FUNCTIONS
    uint private moneyOutThreshold = 100000000000000000;
    uint private fee  = 10;
    // view
    function actualMoneyOutThreshold() external view returns(uint) {return moneyOutThreshold;}
    function actualFee() external view returns(uint) {return fee;}
    // changers
    function changeMoneyOutThreshold(uint _input) external onlyOwner {
        moneyOutThreshold = _input;
    }
    function changeFee(uint _fee) external onlyOwner {
        require(_fee < 100 && _fee >= 0);
        fee = _fee;
    }
            // i wanna add maping for saver and easyer transfer
    // MONEY OUT FUNCTIONS
    function balance() external view returns(uint) {return address(this).balance;}

    function addDeveloper(address _devAddress, uint _code) external onlyOwner {
        require(999 < _code && _code < 10000, "Sorry, only four-digit number"); // only 4 number in code
        devList[_code] = _devAddress;
    }
        function delDeveloper(uint _code) external onlyOwner {
        require(999 < _code && _code < 10000, "Sorry, only four-digit number"); // only 4 number in code
        delete devList[_code];
    }

    function moneyOutTo(uint _code, uint _value) external onlyOwner {
        if (devList[_code] != address(0)) {
            payable(devList[_code]).transfer(_value);
        }
    }

    // MODIFIERS
    modifier onlyOwner {
        require(msg.sender == adminAddress, "Sorry, but you are not an admin <3");
        _;
    }
}