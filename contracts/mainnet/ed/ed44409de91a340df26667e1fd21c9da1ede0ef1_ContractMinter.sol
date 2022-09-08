/**
 *Submitted for verification at Etherscan.io on 2022-09-08
*/

// SPDX-License-Identifier: MIT

// https://github.com/jungleninja/contract-minter

pragma solidity ^0.8.13;

interface IERC721 {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function balanceOf(address owner) external view returns (uint256 balance);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
}

contract subContract{
    address public deployer;
    address public mainContract;
    bool public isInitialized;

    modifier onlyDeployer() {
        require(tx.origin == deployer && msg.sender == mainContract, "only deployer");
        _;
    }

    function initializeC() external {
        require(!isInitialized, "already initialized");
        deployer = tx.origin;
        mainContract = msg.sender;
        isInitialized = true;
    }

    function callData(address _addr, bytes calldata _data) external payable onlyDeployer returns (bytes memory) {
        (bool success, bytes memory result) = _addr.call{value: msg.value}(_data);
        require(success, "call failed");
        return result;
    }

    function transferAllto(address _addr, address _to) external onlyDeployer {
        uint256 balance = IERC721(_addr).balanceOf(address(this));
        while(balance > 0){
            IERC721(_addr).safeTransferFrom(address(this), _to, IERC721(_addr).tokenOfOwnerByIndex(address(this), 0));
            balance--;
        }
    }

    function transferAlltoV2(address _addr, address _to, uint256[] memory _tokenIds) external onlyDeployer {
        for(uint256 i = 0; i < _tokenIds.length; i++){
            IERC721(_addr).safeTransferFrom(address(this), _to, _tokenIds[i]);
        }
    }

    function withdrawETH() external onlyDeployer {
        payable(deployer).transfer(address(this).balance);
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes calldata data) external returns (bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    function onERC1155BatchReceived(address operator, address from, uint256[] calldata ids, uint256[] calldata values, bytes calldata data) external returns (bytes4) {
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }
}


contract ContractMinter {
    address public owner;
    address public subcontract;
    mapping(address => address[]) public subAddressList;

    constructor(){
        owner = msg.sender;
        initialize();
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }

    modifier onlyEOA() {
        require(tx.origin == msg.sender, "only EOA");
        _;
    }

    function initialize() internal {
        require(subcontract == address(0), "already initialized");
        bytes32 salt = keccak256(abi.encodePacked(owner, gasleft(), block.timestamp));
        subcontract = address(new subContract{salt: salt}());
    }

    function deploySubAddrs(uint256 _num) public onlyEOA {
        for(uint256 i = 0; i < _num; i++){
            address subAddr = this.clone(subcontract);
            subContract(subAddr).initializeC();
            subAddressList[msg.sender].push(subAddr);
        }
    }

    function batchCall(uint256 times, address _addr, bytes calldata _data) public payable onlyEOA {
        address sender = msg.sender;
        require(subAddressList[sender].length > 0, "You have not deployed subAddress yet");
        require(_data.length >= 4, "data length must be greater than 4");
        if (times > subAddressList[sender].length) {
            times = subAddressList[sender].length;
        }
        if (msg.value > 0) {
            uint256 WeiValue = msg.value / times;
            for(uint256 i = 0; i < times; i++){
                subContract(subAddressList[sender][i]).callData{value: WeiValue}(_addr, _data);
            }
        } else {
            for(uint256 i = 0; i < times; i++){
                subContract(subAddressList[sender][i]).callData(_addr, _data);
            }
        }
    }

    function withdrawNFTs(address _token, address _to) public onlyEOA {
        address sender = msg.sender;
        require(subAddressList[sender].length > 0, "You have not deployed subAddress yet");
        for (uint256 i = 0; i < subAddressList[sender].length; i++) {
            address subAddr = subAddressList[sender][i];
            subContract(subAddr).transferAllto(_token, _to);
        }
    }

    function withdrawNFTsV2(address _token, address _to, address[] memory _subaddrs, uint256[][] memory _tokenids) public onlyEOA {
        address sender = msg.sender;
        require(_subaddrs.length == _tokenids.length, "length not match");
        for (uint256 i = 0; i < _subaddrs.length; i++) {
            address subAddr = _subaddrs[i];
            subContract(subAddr).transferAlltoV2(_token, _to, _tokenids[i]);
        }
    }

    function withdrawETHEmergency() public onlyEOA {
        address sender = msg.sender;
        require(subAddressList[sender].length > 0, "You have not deployed subAddress yet");
        for (uint256 i = 0; i < subAddressList[sender].length; i++) {
            address subAddr = subAddressList[sender][i];
            uint256 ethBalance = address(subAddr).balance;
            if (ethBalance > 0) {
                subContract(subAddr).withdrawETH();
            }
        }
    }

    function getSubaddressAndTokenids(address _user, address _token) external view returns (address[] memory, uint256[][] memory) {
        uint256[][] memory tokenids = new uint256[][](subAddressList[_user].length);
        address[] memory subaddrs = subAddressList[_user];
        uint256 len = 0;
        for (uint256 i = 0; i < subAddressList[_user].length; i++) {
            address subAddr = subAddressList[_user][i];
            uint256 balance = IERC721(_token).balanceOf(subAddr);
            if (balance > 0) {
                tokenids[i] = new uint256[](balance);
                for (uint256 j = 0; j < balance; j++) {
                    tokenids[i][j] = IERC721(_token).tokenOfOwnerByIndex(subAddr, j);
                }
            } else {
                subaddrs[i] = subaddrs[subaddrs.length - 1];
                delete subaddrs[subaddrs.length - 1];
                tokenids[i] = tokenids[tokenids.length - 1];
                delete tokenids[tokenids.length - 1];
                len++;
            }
        }
        require(subaddrs.length == tokenids.length, "length not match");
        uint256[][] memory tokenids2 = new uint256[][](subaddrs.length - len);
        for (uint256 i = 0; i < tokenids2.length; i++) {
            tokenids2[i] = tokenids[i];
        }
        address[] memory subaddrs2 = new address[](subaddrs.length - len);
        for (uint256 i = 0; i < subaddrs2.length; i++) {
            subaddrs2[i] = subaddrs[i];
        }
        require(subaddrs2.length > 0, "Your subaddress doesn't have this NFTs");
        return (subaddrs2, tokenids2);
    }

    function getSubaddress(address _user) public view returns (uint256, address[] memory) {
        return (subAddressList[_user].length, subAddressList[_user]);
    }

    function clone(address target) external returns (address result) {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(clone,0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(add(clone, 0x28),0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            result := create(0, clone, 0x37)
        }
        require(result != address(0), "clone failed");
    }

}