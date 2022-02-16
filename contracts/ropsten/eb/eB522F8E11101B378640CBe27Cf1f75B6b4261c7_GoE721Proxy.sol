/**
 *Submitted for verification at Etherscan.io on 2022-02-16
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0;

contract ProxyData {
    address internal proxied;
}

contract Proxy is ProxyData {
    constructor(address _proxied) {
        proxied = _proxied;
    }

    function implementation() public view returns (address) {
        return proxied;
    }    
    function proxyType() public pure returns (uint256) {
        return 1; // for "forwarding proxy"
                  // see EIP 897 for more details
    }

    receive() external payable {

    }
   
    fallback () external payable {
        address addr = proxied;
        assembly {
            let freememstart := mload(0x40)
            calldatacopy(freememstart, 0, calldatasize())
            let success := delegatecall(not(0), addr, freememstart, calldatasize(), freememstart, 0)
            returndatacopy(freememstart, 0, returndatasize())
            switch success
            case 0 { revert(freememstart, returndatasize()) }
            default { return(freememstart, returndatasize()) }
        }
    }
}


contract GoE721Data is ProxyData {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    
    string  _name;
    string  _symbol;
    string  _baseUrl;
    string  _baseExtention;
    uint256  _mintIdx;
    uint256 _maxSupply;

    mapping(address => uint256) _mintCost;
    mapping(uint256 => address) _owners;
    mapping(address => uint256) _balances;
    mapping(uint256 => address) _tokenApprovals;
    mapping(address => mapping(address => bool)) _operatorApprovals;

}

contract GoE721Proxy is Proxy, GoE721Data {
     constructor (address proxied, string memory name_, string memory symbol_, string memory baseUri_, string memory baseExt_, uint256 maxSupply_, uint256 nativeMintCost_, uint256[] memory mintCosts_, address[] memory mintTokens_) Proxy(proxied) {
        _name = name_;
        _symbol = symbol_;
        _baseUrl = baseUri_;
        _baseExtention = baseExt_;
        _maxSupply = maxSupply_;
        _mintCost[address(0)] = nativeMintCost_;
        _mintIdx = 1;
        require(mintTokens_.length == mintCosts_.length, "GoE721Proxy: Tokens and Costs need to be the same length");
        for(uint256 i=0; i<mintTokens_.length; i++){
            _mintCost[mintTokens_[i]] = mintCosts_[i];
        }
    }
}