pragma solidity ^0.8.13;

interface IERC721 {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

interface IERC1155 {
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;
}

contract subContract{
    function callData(address _addr, bytes calldata _data) external payable returns (bytes memory) {
        (bool success, bytes memory result) = _addr.call{value: msg.value}(_data);
        require(success, "call failed");
        return result;
    }

    function callDatalimit(address _addr, bytes calldata _data) external payable returns (bytes memory) {
        
        (bool success, bytes memory result) = _addr.call{value: msg.value}(_data);
        require(success, "call failed");
        return result;
    }

    function transferAllto721(address _addr, address _to, uint256 _tokenId) external {
        IERC721(_addr).safeTransferFrom(address(this), _to, _tokenId);
    }

    function transferAllto1155(address _addr, address _to, uint256 _id, uint256 _amount, bytes calldata _data) external {
        IERC1155(_addr).safeTransferFrom(address(this), _to, _id, _amount, _data);
    }

    function withdrawETH(address deployer) external {
        payable(deployer).transfer(address(this).balance);
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes calldata data) external returns (bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }
}

contract Minter {
    address public owner;
    address public subcontract;
    mapping(address => address[]) public subAddressList;

    constructor() {
        owner = msg.sender;
        bytes32 salt = keccak256(abi.encodePacked(owner, gasleft(), block.timestamp));
        subcontract = address(new subContract{salt: salt}());
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }

    function deploySubContracts(uint16 _num) external {
        for(uint16 i = 0; i < _num; i++) {
            address subAddr = this.clone(subcontract);
            subAddressList[msg.sender].push(subAddr);
        }
    }

    function usualMint(uint16 times, uint16 startnum, address _addr, bytes calldata _data) external payable {
        if (msg.value == 0) {
            for(uint16 i = startnum; i < times; i++) {
                subContract(subAddressList[msg.sender][i]).callData(_addr, _data);
            }
        } else {
            uint256 WeiValue = msg.value / times;
            for(uint16 i = startnum; i < times; i++) {
                subContract(subAddressList[msg.sender][i]).callData{value: WeiValue}(_addr, _data);
            }
        }
    }

    function loopMint(uint16 times, address _addr, bytes calldata _data) external payable {
        if (msg.value == 0) {
            for(uint16 i = 0; i < times; i++) {
                subContract(subAddressList[msg.sender][0]).callDatalimit(_addr, _data);
            }
        } else {
            uint256 WeiValue = msg.value / times;
            for(uint16 i = 0; i < times; i++) {
                subContract(subAddressList[msg.sender][0]).callDatalimit{value: WeiValue}(_addr, _data);
            }
        }
    }

    function loopMintlimit(uint16 times, address _addr, bytes[] calldata _data) external payable {
        if (msg.value == 0) {
            for(uint16 i = 0; i < times; i++) {
                subContract(subAddressList[msg.sender][i]).callData(_addr, _data[i]);
            }
        } else {
            uint256 WeiValue = msg.value / times;
            for(uint16 i = 0; i < times; i++) {
                subContract(subAddressList[msg.sender][i]).callData{value: WeiValue}(_addr, _data[i]);
            }
        }
    }

    function claimLoop(uint16 times, uint16 startnum, address original_addr, uint256 tokenId, address mint_addr, bytes calldata _data) external payable {
        for(uint16 i = startnum; i < times - 1; i++) {
            subContract(subAddressList[msg.sender][i]).callData(mint_addr, _data);
            subContract(subAddressList[msg.sender][i]).transferAllto721(original_addr, subAddressList[msg.sender][i + 1], tokenId);
        }
        subContract(subAddressList[msg.sender][startnum + times - 1]).callData(mint_addr, _data);
        subContract(subAddressList[msg.sender][startnum + times - 1]).transferAllto721(original_addr, msg.sender, tokenId);
    }

    function withdraw721(address _token, address _to, address[] calldata _subaddrs, uint256[][] calldata _tokenids) external onlyOwner {
        for (uint16 i = 0; i < _subaddrs.length; i++) {
            for(uint16 j = 0; j < _tokenids[i].length; j++) {
                subContract(_subaddrs[i]).transferAllto721(_token, _to, _tokenids[i][j]);
            }
        }
    }

    function withdraw1155(address _token, address _to, address[] calldata _subaddrs, uint256[] calldata _id, uint256 _amount, bytes calldata _data) external onlyOwner {
        for (uint16 i = 0; i < _subaddrs.length; i++) {
            subContract(_subaddrs[i]).transferAllto1155(_token, _to, _id[i], _amount, _data);
        }
    }

    function getSubaddress(address _address) public view returns (uint256, address[] memory) {
        return (subAddressList[_address].length, subAddressList[_address]);
    }

    function withdrawETH(address _address) external onlyOwner {
        for (uint16 i = 0; i < subAddressList[_address].length; i++) {
            address subAddr = subAddressList[_address][i];
            if (address(subAddr).balance > 0) {
                subContract(subAddr).withdrawETH(owner);
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