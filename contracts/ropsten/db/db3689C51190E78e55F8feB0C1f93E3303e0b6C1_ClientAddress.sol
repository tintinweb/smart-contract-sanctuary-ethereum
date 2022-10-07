pragma solidity ^0.8.0;

contract ClientAddress {

address payable [] public  _clientAddress  = new address payable [](10);

constructor() {


    _clientAddress = [
        payable(0x70997970C51812dc3A010C7d01b50e0d17dc79C8),
        payable(0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC),
        payable(0x90F79bf6EB2c4f870365E785982E1f101E93b906),
        payable(0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65),
        payable(0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc),
        payable(0x976EA74026E726554dB657fA54763abd0C3a0aa9),
        payable(0x14dC79964da2C08b23698B3D3cc7Ca32193d9955),
        payable(0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f),
        payable(0xa0Ee7A142d267C1f36714E4a8F75612F20a79720),
        payable(0xBcd4042DE499D14e55001CcbB24a551F3b954096)];
        
}

function getContractAddress() public view returns (address) {
    return address(this);
}

function getClientAddress() public view  returns (address payable[] memory) {
    return _clientAddress;

}

function getCount() public view returns (uint) {
    return _clientAddress.length;
}

}