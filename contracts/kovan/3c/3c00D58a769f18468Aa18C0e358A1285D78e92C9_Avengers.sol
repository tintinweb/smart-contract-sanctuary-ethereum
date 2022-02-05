// SPDX-License-Identifier: MIT
pragma solidity >=0.7.5;
pragma abicoder v2;

import './FlashLoanReceiverBase.sol';
import './ILendingPool.sol';
//mainnet: 0x24a42fD28C976A61Df5D00D0599C34c4f90748c8
//kovan: 0x506B0B2CF20FAA8f38a4E2B524EE43e1f4458Cc5
contract Avengers is
    FlashLoanReceiverBase(address(0x506B0B2CF20FAA8f38a4E2B524EE43e1f4458Cc5))
{
    address private constant ZX_PROXY = 0xDef1C0ded9bec7F1a1670819833240f027b25EfF;

    ILendingPool private lendingPool;

    constructor() {
        address lendingPoolAddress = addressesProvider.getLendingPool();
        lendingPool = ILendingPool(lendingPoolAddress);
    }

    // Transfer tokens held by this contrat to the sender/owner.
    function withdrawToken(IERC20 token, uint256 amount)
        external onlyOwner
    {
        if(amount == 0){
            amount = token.balanceOf(address(this));
        }
        require(token.transfer(msg.sender, amount));
    }

    // Transfer ETH held by this contrat to the sender/owner.
    function withdrawETH(uint256 amount)
        external onlyOwner
    {
        msg.sender.transfer(amount);
    }

    struct Tokens {
        uint256 amount;
        address token;
        bytes data;
    }

    mapping(uint => Tokens) private tokensMap;
    uint private countTokens = 0;

    function xSwap(uint256 amount, address token) public onlyOwner {
        // countTokens = 0;
        // for(uint i = 0; i < tokens.length; i++){
        //     countTokens++;
        //     tokensMap[countTokens] = tokens[i];
        // }
        
        bytes memory data = "";
        lendingPool.flashLoan(address(this), token, 
                            amount, data);
    }

    function executeOperation(
        address _reserve,
        uint256 _amount,
        uint256 _fee,
        bytes calldata _params
    ) external override onlyOwner {
        
        // xSwap();
        // Repay loan
        uint256 totalDebt = _amount + _fee;
        emit Log(_amount, _reserve, true, "TOTAL LOAN");
        emit Log(_fee, _reserve, true, "TOTAL LOAN FEE");
        transferFundsBackToPoolInternal(_reserve, totalDebt);
    }

    function xSwap() private {
        for(uint i = 1; i <= countTokens; i++){
            Tokens memory token = tokensMap[i];
            IERC20 tok = IERC20(token.token);
            tok.approve(ZX_PROXY, token.amount);

            (bool success,) = ZX_PROXY.call(token.data);
            emit Log(token.amount, token.token,
                success, "SWAP EXECUTED");
        }
    }

    event Log(uint256 amount, address token, bool success, string val);

}