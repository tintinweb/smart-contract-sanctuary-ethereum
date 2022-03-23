// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;
import "./Ownable.sol";
import {ERC20} from "./ERC20.sol";
import {IWETH} from "./IWETH.sol";


contract Treasury is Ownable {

    
    address public immutable WETH;

    event transfer(address user,address currency, uint256 amount);
    event deposit(address currency, uint256 amount);


    /**
     * @notice Constructor
     * @param _WETH WETH Address
     */
    constructor(address _WETH)  {
        WETH = _WETH;
    }

    /**
     * @notice balanceOfERC20 this address
     * @param _currency ERC20 contract address
     */
  function balanceOfERC20(address _currency) public view virtual  returns (uint256) {
        return ERC20(_currency).balanceOf(address(this));
    }

    /**
     * @notice balanceOfWETH this address
     */
   function balanceOfWETH() public view virtual  returns (uint256) {
        return ERC20(WETH).balanceOf(address(this));
    } 

    /**
     * @notice transferERC20To other address from this address
     * @param _to  address
     * @param _currency ERC20 contract address
     * @param _amount amount
     */
    function transferERC20To(address _to, address _currency,uint256 _amount) external onlyOwner {
        require(_to != address(0), "to: Cannot be null address");
        ERC20(_currency).transfer(_to, _amount);
        emit transfer(_to, _currency, _amount);
    }

    /**
     * @notice transferWETHTo other address from this address
     * @param _to  address
     * @param _amount amount
     */
    function transferWETHTo(address _to, uint256 _amount) external onlyOwner {
        require(_to != address(0), "to: Cannot be null address");
        require(_amount <= ERC20(WETH).balanceOf(address(this)), "amount: Cannot less than 0");
        ERC20(WETH).transfer(_to, _amount);
        emit transfer(_to, WETH, _amount);
    }


    /**
     * @notice depositToWETH to this address with ETH
     */
    function depositToWETH() external payable  {
        require(msg.value > 0, "msg.value cannot less than 0");
        // Wrap ETH sent to this contract
        IWETH(WETH).deposit{value: msg.value}();
        emit deposit(WETH, msg.value);
    }




}