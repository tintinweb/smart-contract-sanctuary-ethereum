/**
 *Submitted for verification at Etherscan.io on 2022-07-14
*/

// SPDX-License-Identifier: No License (None)
pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface ISmartSwap {
    function isSystem(address caller) external returns(bool);   // check if caller is system wallet.
    function decimals(address token) external returns(uint256);   // token address => token decimals
    function processingFee() external returns(uint256); // Processing fee
    function companyFee() external returns(uint256); // Company fee
    //function reimburse(address user, uint256 amount) external; // reimburse user for SP payment
    function swap(
        address tokenA,
        address tokenB, 
        address receiver,
        uint256 amountA,
        address licensee,
        bool isInvestment,
        uint128 minimumAmountToClaim,   // do not claim on user behalf less of this amount. Only exception if order fulfilled.
        uint128 limitPice,   // Do not match user if token A price less this limit
        uint256 fee          // company + licensee fee amount
    )
        external
        payable
        returns (bool);

    function cancel(
        address tokenA,
        address tokenB, 
        address receiver,
        uint256 amountA    //amount of tokenA to cancel
    )
        external
        payable
        returns (bool);

    function claimToken(
        address tokenA, // foreignToken
        address tokenB, // nativeToken
        address sender,
        address receiver,
        uint128 amountA,    //amount of tokenA that has to be swapped
        uint128 currentRate,     // rate with 18 decimals: tokenA price / tokenB price
        uint256 foreignBalance,  // total tokens amount sent by user to pair on other chain
        uint256 foreignSpent,   // total tokens spent by SmartSwap pair
        uint256 nativeEncoded   // (nativeRate, nativeSpent) = _decode(nativeEncoded)
    )   
        external
        returns (bool);
}

contract SPContractNoOracle{

    address public owner;
    address public nativeTokenReceiver;
    address public nativeToken;
    mapping(address => address) public foreignToken;    // SmartSwap => foreign token
    mapping(address => address) public foreignTokenReceiver;    // SmartSwap => receiver address where tokens will be transferred from SmartSwap

    //ISmartSwap public smartSwap; // assign SmartSwap address here
    uint256 private feeAmountLimit; // limit of amount that System withdraw for fee reimbursement
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event FeeTransfer(address indexed systemWallet, uint256 fee);
    event Deposit(uint256 value);

    // run only once from proxy
    function initialize(
        address _owner,     // contract owner
        address _nativeToken, // native token that will be send to SmartSwap
        address _nativeTokenReceiver, // address on Binance to deposit native token
        uint256 _feeAmountLimit, // limit of amount that System may withdraw for fee reimbursement
        address[] calldata _foreignToken, // foreign token that has to be received from SmartSwap (on foreign chain)
        address[] calldata _foreignTokenReceiver, // address of foreign SP contract deposit foreign token
        address[] calldata _smartSwap   // address of local SmartSwap contract
    )
        external
    {
        require(owner == address(0)); // run only once
        require(
            _nativeToken != address(0)
            && _nativeTokenReceiver != address(0)
        );
        nativeToken = _nativeToken;
        nativeTokenReceiver = _nativeTokenReceiver;
        for (uint i; i < _smartSwap.length; i++) {
            foreignTokenReceiver[_smartSwap[i]] = _foreignTokenReceiver[i];
            foreignToken[_smartSwap[i]] = _foreignToken[i];
        }
        feeAmountLimit = _feeAmountLimit;
        //smartSwap = ISmartSwap(_smartSwap[0]);
        owner = _owner;
        emit OwnershipTransferred(address(0), _owner);
    }

    receive() external payable {
        emit Deposit(msg.value);
    }

    /**
    * @dev Throws if called by any account other than the system.
    */
    modifier onlySystem(address _smartSwap) {
        require(ISmartSwap(_smartSwap).isSystem(msg.sender), "Caller is not the system");
        _;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    // set limit of amount that System withdraw for fee reimbursement
    function setFeeAmountLimit(uint256 amount) external onlyOwner {
        feeAmountLimit = amount;
    }


    // set limit of amount that System withdraw for fee reimbursement
    function setForeignToken(address _localSmartSwap, address _foreignToken, address _foreignTokenReceiver) external onlyOwner {
        foreignTokenReceiver[_localSmartSwap] = _foreignTokenReceiver;
        foreignToken[_localSmartSwap] = _foreignToken;
    }

    // get limit of amount that System withdraw for fee reimbursement
    function getFeeAmountLimit() external view returns(uint256) {
        return feeAmountLimit;
    }

    function cancel(address smartSwap, uint256 amount) external onlySystem(smartSwap) {
        ISmartSwap(smartSwap).cancel(nativeToken, foreignToken[smartSwap], foreignTokenReceiver[smartSwap], amount);
    }

    // Allow owner withdraw tokens from contract
    function withdraw(address token, uint256 amount) external onlyOwner {
        if (token < address(9))
            safeTransferETH(msg.sender, amount);
        else
            safeTransfer(token, msg.sender, amount);
    }

    // Allow owner withdraw tokens from contract
    function withdrawSystem(address smartSwap, uint256 amount) external onlySystem(smartSwap) {
        require(foreignTokenReceiver[smartSwap] != address(0), "Wrong smartSwap");
        address token = nativeToken;
        if (token < address(9))
            safeTransferETH(nativeTokenReceiver, amount);
        else
            safeTransfer(token, nativeTokenReceiver, amount);
    }    



    // add liquidity to counterparty 
    function addLiquidityAndClaimBehalf(
        address smartSwap, // address of local SmartSwap
        uint256 feeAmount,   // processing fee amount to reimburse system wallet.
        uint128 amount,    //amount of native token that has to be swapped (amount of provided liquidity)
        uint128 currentRate,     // rate with 18 decimals: tokenB price / tokenA price
        uint128[] memory claimAmount, // claim amount (in foreign tokens).
        uint256[] memory foreignBalance,  // total tokens amount sent by user to pair on other chain
        address[] memory senderCounterparty, // correspondent value from SwapRequest event
        address[] memory receiverCounterparty,    // correspondent value from SwapRequest event
        uint256 foreignSpent,   // total tokens spent by SmartSwap pair
        uint256 nativeEncoded   // (nativeRate, nativeSpent) = _decode(nativeEncoded)        
    ) 
        external 
        onlySystem(smartSwap) 
    {
        require(feeAmountLimit >= feeAmount, "Fee limit exceeded");
        require(foreignTokenReceiver[smartSwap] != address(0), "Wrong smartSwap");

        feeAmountLimit -= feeAmount;
        require(claimAmount.length == foreignBalance.length &&
            senderCounterparty.length == receiverCounterparty.length &&
            foreignBalance.length == senderCounterparty.length,
            "Wrong length"
        );
        // send swap request
        swap(smartSwap, amount, feeAmount);
        // claim tokens on users behalf
        claimBehalf(smartSwap, currentRate, claimAmount, foreignBalance, senderCounterparty, receiverCounterparty, foreignSpent, nativeEncoded);
    }

    function claimBehalf(
        address smartSwap, // address of local SmartSwap
        uint128 currentRate,     // rate with 18 decimals: tokenB price / tokenA price
        uint128[] memory claimAmount, // claim amount (in foreign tokens).
        uint256[] memory foreignBalance,  // total tokens amount sent by user to pair on other chain
        address[] memory senderCounterparty, // correspondent value from SwapRequest event
        address[] memory receiverCounterparty,    // correspondent value from SwapRequest event
        uint256 foreignSpent,   // total tokens spent by SmartSwap pair
        uint256 nativeEncoded   // (nativeRate, nativeSpent) = _decode(nativeEncoded)  
    ) 
        internal 
    {
        //uint256 totalAmount;
        address _foreignToken = foreignToken[smartSwap];
        for (uint256 i = 0; i < claimAmount.length; i++) {
            //totalAmount += claimAmount[i];
            ISmartSwap(smartSwap).claimToken(
                _foreignToken,
                nativeToken,
                senderCounterparty[i],
                receiverCounterparty[i],
                claimAmount[i],
                currentRate, 
                foreignBalance[i],
                foreignSpent,
                nativeEncoded
            );
        }
        //require(totalAmount * currentRate / (10**(18+t.foreignDecimals-t.nativeDecimals)) <= uint256(amount), "Insuficiant amount");
    }

    function swap(address smartSwap, uint128 amount, uint256 feeAmount) internal {
        uint256 processingFee = ISmartSwap(smartSwap).processingFee();
        if (nativeToken > address(9)) {
            // can't get company fee amount
            IERC20(nativeToken).approve(address(smartSwap), uint256(amount));
            ISmartSwap(smartSwap).swap{value: processingFee}(
                nativeToken, 
                foreignToken[smartSwap],
                foreignTokenReceiver[smartSwap], 
                amount, 
                address(0),
                false, 
                0,
                0,
                0
            );            
        } else {    // native coin (ETH, BNB)
            uint256 fee = uint256(amount)*ISmartSwap(smartSwap).companyFee()/10000;  // company fee
            processingFee = fee + processingFee;
            ISmartSwap(smartSwap).swap{value: uint256(amount) + processingFee}(
                nativeToken, 
                foreignToken[smartSwap],
                foreignTokenReceiver[smartSwap], 
                amount, 
                address(0),
                false, 
                0,
                0,
                fee
            );
        }
        require(processingFee <= feeAmount, "Insuficiant fee");
        feeAmount -= processingFee; // we already paid processing fee to SmartSwap contract
        if (feeAmount != 0) {
            payable(msg.sender).transfer(feeAmount);
            emit FeeTransfer(msg.sender, feeAmount);
        }        
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TRANSFER_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'ETH_TRANSFER_FAILED');
    }
}