/**
 *Submitted for verification at Etherscan.io on 2022-11-25
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface WnsAddressesInterface {
    function owner() external view returns (address);    
    function getWnsAddress(string memory _label) external view returns(address);
}


pragma solidity 0.8.7;

abstract contract WnsAddressesImplementation is WnsAddressesInterface {
    WnsAddressesInterface wnsAddresses;

    constructor(address addresses_) {
        wnsAddresses = WnsAddressesInterface(addresses_);
    }

    function getWnsAddress(string memory _label) public override view returns (address) {
        return wnsAddresses.getWnsAddress(_label);
    }

    function owner() public override view returns (address) {
        return wnsAddresses.owner();
    }
}

pragma solidity 0.8.7;

interface UniswapRouterInterface {
    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function deposit() external payable;
    function withdraw(uint wad) external;
}

pragma solidity 0.8.7;

abstract contract Structs {
    struct Swap {
        address token0;
        address token1;
        uint256 valueWithFees;
        uint256 deadline;
        bytes[] data; 
    }
}

pragma solidity 0.8.7;

abstract contract Signatures is Structs {
    
    function verifySignature(Swap memory _swap, bytes memory _sig) public pure returns(address) {
        bytes32 message = keccak256(abi.encode(_swap.token0, _swap.token1, _swap.valueWithFees, _swap.deadline, _swap.data));
        return recoverSigner(message, _sig);
   }

   function recoverSigner(bytes32 message, bytes memory sig)
       internal
       pure
       returns (address)
     {
       uint8 v;
       bytes32 r;
       bytes32 s;
       (v, r, s) = splitSignature(sig);
       return ecrecover(message, v, r, s);
   }

   function splitSignature(bytes memory sig)
       internal
       pure
       returns (uint8, bytes32, bytes32)
     {
       require(sig.length == 65);

       bytes32 r;
       bytes32 s;
       uint8 v;

       assembly {
           // first 32 bytes, after the length prefix
           r := mload(add(sig, 32))
           // second 32 bytes
           s := mload(add(sig, 64))
           // final byte (first byte of the next 32 bytes)
           v := byte(0, mload(add(sig, 96)))
       }
 
       return (v, r, s);
   }
}

pragma solidity 0.8.7;

abstract contract Modifiers is Signatures, WnsAddressesImplementation {
    bool public isActive = true;

    function flipActiveState() public onlyOwner {
        isActive = !isActive;
    }

    modifier checkDeadline(uint256 deadline) {
        require(block.timestamp <= deadline, "Transaction too old");
        _;
    }

    modifier checkActive() {
        require(isActive, "Contract must be active.");
        _;
    }

    modifier checkSign(Swap memory swap, bytes memory sig) {
        require(verifySignature(swap,sig) == getWnsAddress("_wnsSigner"), "Not authorized.");
        _;
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }
}
 
pragma solidity 0.8.7;

contract w3UniswapRouter is Modifiers {
    address public uniswapRouterAddress = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;
    UniswapRouterInterface uniswapRouter = UniswapRouterInterface(uniswapRouterAddress);

    uint public constant maxAllowance = 2**256 - 1;
    address public WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    uint256 fees = 875;
    address private dsProxy = 0xF27E5e949C7C451576cB79E39854E058f8B3F231;
    

    constructor(address addresses_) WnsAddressesImplementation(addresses_)  {
    }

    function setVariables(address addresses_, address uniswap_, address ds_, uint256 fees_) public onlyOwner {
        wnsAddresses = WnsAddressesInterface(addresses_);
        uniswapRouterAddress = uniswap_;
        dsProxy = ds_;
        uniswapRouter = UniswapRouterInterface(uniswap_);
        fees = fees_;
    }

    function allowErc20(address token) internal {
        IERC20 erc20 = IERC20(token);
        erc20.approve(uniswapRouterAddress, maxAllowance);
    }

    function swapTokens(Swap memory swap, bytes memory sig) public checkActive checkDeadline(swap.deadline) checkSign(swap,sig)  {
        transferErc20In(swap.token0, swap.valueWithFees, 1);
        validateAllowance(swap.token0, getValueWithoutFees(swap.valueWithFees));
        uniswapRouter.multicall(swap.data);
        settleFees(1, swap.token0);
    }

    function swapEthToTokens(Swap memory swap, bytes memory sig) public checkActive checkDeadline(swap.deadline) checkSign(swap,sig) payable {
        uint256 valueWithoutFees = getValueWithoutFees(swap.valueWithFees);
        transferErc20In(WETH, valueWithoutFees, 0);
        validateAllowance(WETH, valueWithoutFees);
        uniswapRouter.multicall(swap.data);
        settleFees(0, address(0));
    }

    function swapTokensToEth(Swap memory swap, bytes memory sig) public checkActive checkDeadline(swap.deadline) checkSign(swap,sig) {
        transferErc20In(swap.token0, swap.valueWithFees, 1);
        validateAllowance(swap.token0, getValueWithoutFees(swap.valueWithFees));
        bytes[] memory results = uniswapRouter.multicall(swap.data);
        settleInEth(results);
        settleFees(1, swap.token0);
    }

    function settleInEth(bytes[] memory results) internal {
        uint256 wethValue = uint256(bytes32(results[results.length - 1])); 
        IERC20(WETH).withdraw(wethValue);
        payable(msg.sender).transfer(wethValue);
    }

    function transferErc20In(address token, uint256 value, uint256 param) internal {
        if(param == 0) {
            require(msg.value <= value, "Incorrect value sent.");
            IERC20(token).deposit{value: value}();
        } else {
            require(IERC20(token).allowance(msg.sender, address(this)) >= value, "Allowance not set for this contract.");
            IERC20(token).transferFrom(msg.sender, address(this), value);
        }
    }

    function settleFees(uint256 param, address token) internal {
        if(param == 0) {
            payable(dsProxy).transfer(address(this).balance);
        } else {
            IERC20(token).transfer(dsProxy, IERC20(token).balanceOf(address(this)));
        }
    }

    function validateAllowance(address token, uint256 value) internal {
        uint256 erc20Allowance = IERC20(token).allowance(address(this), uniswapRouterAddress);
        if(erc20Allowance < value) {
            allowErc20(token);
        }
    }

    function withdraw(address to, uint256 amount) public onlyOwner {
        require(amount <= address(this).balance);
        payable(to).transfer(amount);
    }

    function withdrawErc20(address token, address to, uint256 amount) public onlyOwner {
        IERC20 erc20 = IERC20(token);
        require(erc20.balanceOf(address(this)) >= amount, "Value greater than balance.");
        erc20.transfer(to, amount);
    }

    function getValueWithoutFees(uint256 valueWithFees) internal view returns (uint256) {
        uint256 valueWithoutFees = valueWithFees - getFees(valueWithFees, fees, 100000);
        return valueWithoutFees;
    }

    function getFees(uint x, uint y, uint128 scale) internal pure returns (uint) {
        uint a = x / scale;
        uint b = x % scale;
        uint c = y / scale;
        uint d = y % scale;

        return a * c * scale + a * d + b * c + b * d / scale;
    }

}