/**
 *Submitted for verification at Etherscan.io on 2022-10-09
*/

pragma solidity =0.6.12;
pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: MIT

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint256);
}

interface IERC721 {
    function balanceOf(address account) external view returns (uint256);

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "e0");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "e1");
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ow1");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ow2");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "e4");
        (bool success, bytes memory returndata) = target.call{value : weiValue}(data);
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "e5");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "e6");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "e7");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "e8");
        uint256 c = a / b;
        return c;
    }
}

contract transferHelper is Ownable {
    using SafeMath for uint256;
    using Address for address;
    using SafeERC20 for IERC20;

    struct transferItem {
        address _account;
        uint256 _amount;
    }

    struct erc721Item {
        address _account;
        uint256[] tokenIDList;
    }

    function transferEth1(transferItem[] memory transferList) external payable {
        uint256 balance = msg.value;
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < transferList.length; i++) {
            payable(transferList[i]._account).transfer(transferList[i]._amount);
            totalAmount = totalAmount.add(transferList[i]._amount);
        }
        if (balance > totalAmount) {
            payable(msg.sender).transfer(balance.sub(totalAmount));
        }
    }

    function transferEth2(address[] memory _addressList, uint256[] memory _amountList) external payable {
        require(_addressList.length == _amountList.length);
        uint256 balance = msg.value;
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < _addressList.length; i++) {
            payable(_addressList[i]).transfer(_amountList[i]);
            totalAmount = totalAmount.add(_amountList[i]);
        }
        if (balance > totalAmount) {
            payable(msg.sender).transfer(balance.sub(totalAmount));
        }
    }

    function transferEth3(address[] memory _addressList, uint256 _amount) external payable {
        uint256 balance = msg.value;
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < _addressList.length; i++) {
            payable(_addressList[i]).transfer(_amount);
            totalAmount = totalAmount.add(_amount);
        }
        if (balance > totalAmount) {
            payable(msg.sender).transfer(balance.sub(totalAmount));
        }
    }

    function transferErc20Token1(IERC20 _token, transferItem[] memory transferList) external {
        for (uint256 i = 0; i < transferList.length; i++) {
            _token.safeTransferFrom(msg.sender, transferList[i]._account, transferList[i]._amount);
        }
    }

    function transferErc20Token2(IERC20 _token, address[] memory _addressList, uint256[] memory _amountList) external {
        require(_addressList.length == _amountList.length, "e001");
        for (uint256 i = 0; i < _addressList.length; i++) {
            _token.safeTransferFrom(msg.sender, _addressList[i], _amountList[i]);
        }
    }

    function transferErc20Token3(IERC20 _token, address[] memory _addressList, uint256 _amount) external {
        for (uint256 i = 0; i < _addressList.length; i++) {
            _token.safeTransferFrom(msg.sender, _addressList[i], _amount);
        }
    }

    //not extract tokenId
    function transferErc721Token1(IERC721 _nftToken, transferItem[] memory transferList) external {
        for (uint256 i = 0; i < transferList.length; i++) {
            address _account = transferList[i]._account;
            uint256 _amount = transferList[i]._amount;
            for (uint256 j = 0; j < _amount; j++) {
                _nftToken.safeTransferFrom(msg.sender, _account, _nftToken.tokenOfOwnerByIndex(msg.sender, 0));
            }
        }
    }

    function transferErc721Token2(IERC721 _nftToken, address[] memory _addressList, uint256[] memory _amountList) external {
        for (uint256 i = 0; i < _addressList.length; i++) {
            address _acccount = _addressList[i];
            uint256 _amount = _amountList[i];
            for (uint256 j = 0; j < _amount; j++) {
                _nftToken.safeTransferFrom(msg.sender, _acccount, _nftToken.tokenOfOwnerByIndex(msg.sender, 0));
            }
        }
    }

    function transferErc721Token3(IERC721 _nftToken, address[] memory _addressList, uint256 _amount) external {
        for (uint256 i = 0; i < _addressList.length; i++) {
            address _acccount = _addressList[i];
            for (uint256 j = 0; j < _amount; j++) {
                _nftToken.safeTransferFrom(msg.sender, _acccount, _nftToken.tokenOfOwnerByIndex(msg.sender, 0));
            }
        }
    }

    function transferErc721Token4(IERC721 _nftToken, erc721Item[] memory transferList2) external {
        for (uint256 i = 0; i < transferList2.length; i++) {
            erc721Item memory x = transferList2[i];
            address _acccount = x._account;
            uint256[] memory tokenIDList = x.tokenIDList;
            for (uint256 j = 0; j < tokenIDList.length; j++) {
                _nftToken.safeTransferFrom(msg.sender, _acccount, tokenIDList[j]);
            }
        }
    }

    function takeETH() external onlyOwner {
        require(address(this).balance > 0, "e001");
        payable(msg.sender).transfer(address(this).balance);
    }

    function takeErc20Token(IERC20 _token) external onlyOwner {
        require(_token.balanceOf(address(this)) > 0, "e001");
        _token.transfer(msg.sender, _token.balanceOf(address(this)));
    }

    function takeErc721Token(IERC721 _nftToken, uint256 _amount) external onlyOwner {
        require(_nftToken.balanceOf(address(this)) >= _amount && _amount > 0, "e001");
        for (uint256 i = 0; i < _amount; i++) {
            _nftToken.transferFrom(address(this), msg.sender, _nftToken.tokenOfOwnerByIndex(address(this), 0));
        }
    }

    receive() payable external {}
}