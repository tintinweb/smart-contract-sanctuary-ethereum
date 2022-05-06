/**

* MIT License
* ===========
*
* Copyright (c) 2022 SeedBox
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*
*/


pragma solidity 0.8.0;

import './LERC20.sol';
import './Address.sol';
import './SafeMath.sol';

contract SEEDBOX is LERC20 {
    using SafeMath for uint256;
    using Address for address;

    address public _treasury;

    mapping(address => bool) public feeCharge;
    mapping(address => bool) public blacklistedContracts;

    uint256 public _treasuryFee;
    uint256 public constant maxFee = 1500;
    uint256 public constant percentageConst = 10000;
    bool public feeEnabled;

    modifier notInBlackListContracts() {
        require(
            (address(msg.sender).isContract() && !blacklistedContracts[msg.sender]) ||
                !address(msg.sender).isContract(),
            'Address: should be allowed'
        );
        _;
    }

    constructor(
        uint256 totalSupply_,
        string memory name_,
        string memory symbol_,
        address admin_,
        address recoveryAdmin_,
        uint256 timelockPeriod_,
        address lossless_,
        address treasuryPool
    )
        LERC20(
            totalSupply_,
            name_,
            symbol_,
            admin_,
            recoveryAdmin_,
            timelockPeriod_,
            lossless_
        )
    {
        _setTreasury(treasuryPool);
        _setFees(100);
        feeEnabled = false;
    }

    function updateTreasury(address treasury) external onlyOwner {
        _setTreasury(treasury);
    }

    function addFeeChargeAddress(address _free) external onlyOwner {
        feeCharge[_free] = true;
    }

    function deleteFeeChargeAddress(address _free) external onlyOwner {
        feeCharge[_free] = false;
    }

    function enableFee(bool status) external onlyOwner {
        feeEnabled = status;
    }

    function updateFee(uint256 fee) external onlyOwner {
        _setFees(fee);
    }

    function addBlacklistedContract(address _contract) external onlyOwner returns (bool) {
        require(_contract.isContract(), 'Address: is not contract or not deployed');
        blacklistedContracts[_contract] = true;
        return true;
    }

    function removeBlacklistedContract(address _contract) external onlyOwner returns (bool) {
        require(_contract.isContract(), 'Address: is not contract or not deployed');
        blacklistedContracts[_contract] = false;
        return true;
    }

    function transferValueToSend(address sender, uint256 amount)
        public
        view
        returns (uint256)
    {
        return
            feeCharge[sender]
                ? amount
                : amount.sub(
                    amount.mul(_treasuryFee).div(percentageConst)
                );
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        notInBlackListContracts
        returns (bool)
    {

        if (feeCharge[msg.sender] && feeEnabled) {
            require(balanceOf(msg.sender) >= amount, 'Insufficient balance');
            uint256 feeAmount;
            uint256 sendingAmount;
            feeAmount = amount.mul(_treasuryFee).div(percentageConst);
            sendingAmount = amount.sub(feeAmount);
            require(
                super.transfer(recipient, sendingAmount),
                'Transfer Error: Cannot transfer'
            );
            if (feeAmount > 0) {
                require(super.transfer(_treasury, feeAmount), 'Transfer Error: Cannot transfer');
            }
        } else {
            require(super.transfer(recipient, amount), 'Transfer Error: Cannot transfer');
        }
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override notInBlackListContracts returns (bool) {

        if (feeCharge[recipient] && feeEnabled) {
            require(balanceOf(sender) >= amount, 'Insufficient balance');
            uint256 feeAmount;
            uint256 sendingAmount;
            feeAmount = amount.mul(_treasuryFee).div(percentageConst);
            sendingAmount = amount.sub(feeAmount);

            require(
                super.transferFrom(sender, recipient, sendingAmount),
                'Transfer Error: Cannot transfer'
            );
            if(feeAmount > 0) {
                require(
                    super.transferFrom(sender, _treasury, feeAmount),
                    'Transfer Error: Cannot transfer'
                );
            }
        } else {
            require(
                super.transferFrom(sender, recipient, amount),
                'Transfer Error: Cannot transfer'
            );
        }
        return true;
    }

    function sendBack(address _token) public onlyOwner returns (bool) {
        IERC20(_token).transfer(_msgSender(), IERC20(_token).balanceOf(address(this)));
        return true;
    }

    function _setFees(uint256 fee) internal {
        require(fee <= maxFee, 'Fee: value exceeded limit');
        _treasuryFee = fee;
    }

    function _setTreasury(address pool) internal {
        require(pool != address(0), 'Zero address not allowed');
        _treasury = pool;
    }
}