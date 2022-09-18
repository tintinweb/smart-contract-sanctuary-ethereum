pragma solidity ^0.8.13;

interface IERC721 {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function balanceOf(address owner) external view returns (uint256 balance);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
}

contract subContract{
    address private mainContract;
    address private deployer;

    modifier onlyDeployer() {
        require(tx.origin == deployer || msg.sender == mainContract, "only deployer");
        _;
    }

    constructor() {
        mainContract = msg.sender;
        deployer = tx.origin;
    }

    function initializeC() external {
        deployer = tx.origin;
        mainContract = msg.sender;
    }

    function callData(address _addr, bytes calldata _data) external payable onlyDeployer {
        _addr.call{value: msg.value}(_data);
    }

    function transferAllto(address _addr, address _to, uint16[] memory _tokenIds) external onlyDeployer {
        for(uint16 i = 0; i < _tokenIds.length; i++) {
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


contract Minter {
    address public owner;
    address public subcontract;
    address[] public subAddressList;

    struct AddressInfo {
        address _contract;
        uint balance;
    }

    constructor() {
        owner = msg.sender;
        bytes32 salt = keccak256(abi.encodePacked(owner, gasleft(), block.timestamp));
        subcontract = address(new subContract{salt: salt}());
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }

    function deploySubAddrs(uint16 _num) external onlyOwner {
        for(uint16 i = 0; i < _num; i++) {
            address subAddr = this.clone(subcontract);
            subContract(subAddr).initializeC();
            subAddressList.push(subAddr);
        }
    }

    function batchCall(uint16 times, address _addr, bytes calldata _data) external payable onlyOwner {
        if (msg.value == 0) {
            for(uint16 i = 0; i < times; i++) {
                subContract(subAddressList[i]).callData(_addr, _data);
            }
        } else {
            uint256 WeiValue = msg.value / times;
            for(uint16 i = 0; i < times; i++){
                subContract(subAddressList[i]).callData{value: WeiValue}(_addr, _data);
            }
        }
    }

    function withdrawNFTs(address _token, address[] calldata _subaddrs, uint16[][] calldata _tokenids) external onlyOwner {
        for (uint16 i = 0; i < _subaddrs.length; i++) {
            subContract(_subaddrs[i]).transferAllto(_token, owner, _tokenids[i]);
        }
    }

    function getSubaddress() public view returns (uint256, address[] memory) {
        return (subAddressList.length, subAddressList);
    }

    function withdrawETH() external onlyOwner {
        for (uint16 i = 0; i < subAddressList.length; i++) {
            address subAddr = subAddressList[i];
            if (address(subAddr).balance > 0) {
                subContract(subAddr).withdrawETH();
            }
        }
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