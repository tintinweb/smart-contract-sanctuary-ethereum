// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./IERC165.sol";
import "./OFTCore.sol";
import "./AuthAdmin.sol";
import "./IOFT.sol";

interface d2OLike {
    function decreaseAllowanceAdmin(address owner, address spender, uint256 subtractedValue) external returns (bool);
    function totalSupply() external view returns (uint256 supply);
    function burn(address,uint256) external;
    function mintAndDelay(address,uint256) external;
}

contract LayerZeroPipe is OFTCore, IOFT, AuthAdmin("LayerZeroPipe", msg.sender) {

    address public immutable d2OContract;

    event MintLayerZero(address indexed from, uint256 amount, uint16 _srcChainId);
    event BurnLayerZero(address indexed from, uint256 amount, uint16 _dstChainId);

    constructor(address _lzEndpoint, address _d2OContract) OFTCore(_lzEndpoint) {
        require(_lzEndpoint != address(0) && _d2OContract != address(0), "d2OConnectorLZ/invalid address");
        d2OContract = _d2OContract;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(OFTCore, IERC165) returns (bool) {
        return interfaceId == type(IOFT).interfaceId || interfaceId == type(IERC20).interfaceId || super.supportsInterface(interfaceId);
    }

    function circulatingSupply() public view virtual override returns (uint) {
        return d2OLike(d2OContract).totalSupply();
    }

    function _debitFrom(address _from, uint16 _dstChainId, bytes memory, uint _amount) internal virtual override alive {
        address spender = _msgSender();
        if (_from != spender) {
            require(d2OLike(d2OContract).decreaseAllowanceAdmin(_from, spender, _amount),"d2OConnectorLZ/Must have proper allowance");
        }
        d2OLike(d2OContract).burn(_from, _amount);
        emit BurnLayerZero(_from, _amount, _dstChainId);
    }

    function _creditTo(uint16 _srcChainId, address _toAddress, uint _amount) internal virtual override alive {
        d2OLike(d2OContract).mintAndDelay(_toAddress, _amount);
        emit MintLayerZero(_toAddress, _amount, _srcChainId);
    }

    function setTrustedRemoteAuth(uint16 _srcChainId, bytes calldata _path) external auth {
        trustedRemoteLookup[_srcChainId] = _path;
        emit SetTrustedRemote(_srcChainId, _path);
    }
    
    function setTrustedRemoteAddressAuth(uint16 _remoteChainId, bytes calldata _remoteAddress) external auth {
        trustedRemoteLookup[_remoteChainId] = abi.encodePacked(_remoteAddress, address(this));
        emit SetTrustedRemoteAddress(_remoteChainId, _remoteAddress);
    }
}