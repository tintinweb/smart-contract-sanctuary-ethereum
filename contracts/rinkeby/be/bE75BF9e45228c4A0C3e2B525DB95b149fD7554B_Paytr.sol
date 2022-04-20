// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";


interface IErc20 {
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function allowance(address owner, address spender) external view returns (uint256);

}

interface CEth {
    function mint() external payable;

    function exchangeRateCurrent() external returns (uint256);

    function supplyRatePerBlock() external returns (uint256);

    function redeem(uint) external returns (uint);

    function redeemUnderlying(uint) external returns (uint);
}

interface CErc20 {
    function mint(uint256) external returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function supplyRatePerBlock() external returns (uint256);

    function redeem(uint) external returns (uint);

    function redeemUnderlying(uint) external returns (uint);
}



contract Paytr is Ownable {
    event MyLog(string, uint256);
    event MyOwnLog(string, uint);
    event PaymentInfo(uint256 amount, bytes paymentReference, address supplier );
    event PayoutInfo(address sender, uint256 amount, bytes paymentReference, uint dueDate, address supplier);
    event PaymentInfoErc20(address tokenAddress, address sender, address supplier, uint256 amount, uint256 dueDate, bytes paymentReference);
    event PaymentInfoErc20WithFee(address tokenAddress, address supplier, uint256 amount, bytes paymentReference, uint256 feeAmount, address feeAddress);
    event PayOutInfoErc20(address sender, uint256 interestAmount, address supplier, uint256 amount, bytes paymentReference, uint dueDate, address tokenAddress);
    


    IErc20 public daitoken;
    IErc20 public USDCtoken;

    
    address sender;
    address tokenAddress;
    
    
    
    struct Invoice {
        uint amount;
        address sender;
        address supplier;
        uint256 dueDate;
        bytes paymentReference;
    }

    struct InvoiceErc20 {
        uint amount;
        address sender;
        address supplier;
        uint256 dueDate;
        bytes paymentReference;
        address tokenAddress;
    }
  
    struct dueInvoice {
        uint amount;
        address sender;
        address supplier;
        uint dueDate;
        bytes paymentReference;
    }
    
    struct dueInvoiceErc20 {
        uint amount;
        uint interestAmount;
        address sender;
        address supplier;
        uint48 dueDate;
        bytes paymentReference;
        address tokenAddress;
    }
   

   
   Invoice[] public invoices;
   dueInvoice[] public dueInvoices;
   InvoiceErc20[] public invoicesErc20;
   dueInvoiceErc20[] public dueInvoicesErc20;

   error TransferErc20Failed();

   constructor() {
        
        daitoken = IErc20(0x5592EC0cfb4dbc12D3aB100b257153436a1f0FEa); //Rinkeby DAI contract address
        USDCtoken = IErc20(0x4DBCdF9B62e891a7cec5A2568C3F4FAF9E8Abe2b); //Rinkeby USDC contract address
        }

     

    function supplyEthToCompound(address payable _cEtherContract, uint amount, address supplier, uint256 dueDate, bytes memory paymentReference)
        public
        payable
        returns (bool)
    {
        // Create a reference to the corresponding cToken contract
        CEth cToken = CEth(_cEtherContract);
        
        dueDate = block.timestamp + (dueDate * 1 seconds);
        Invoice memory invoiceData = Invoice(amount, msg.sender, supplier, dueDate, paymentReference);
        invoices.push(invoiceData);

        // address sender, uint256 amount, bytes paymentReference, address supplier 
        emit PaymentInfo(amount, paymentReference, supplier);

        cToken.mint{value:msg.value,gas:250000}();
        return true;
    }



    function transferAndSupplyErc20ToCompound (
        address _erc20Contract,
        address _cErc20Contract,
        uint256 amount,
        address supplier,
        uint256 dueDate,
        bytes memory paymentReference
        ) public returns (uint) {
        
        // Create a reference to the underlying asset contract, like DAI.
        IErc20 underlying = IErc20(_erc20Contract);                

        // Create a reference to the corresponding cToken contract, like cDAI
        CErc20 cToken = CErc20(_cErc20Contract);

        require(amount > 0, "You need to input an mount bigger than 0");
        

        // Approve transfer on the ERC20 contract
        bool success = underlying.approve(_cErc20Contract, amount);
        if (!success) revert TransferErc20Failed();
      
        dueDate = block.timestamp + (dueDate * 1 seconds);
        InvoiceErc20 memory invoiceDataErc20 = InvoiceErc20(amount, msg.sender, supplier, dueDate, paymentReference, _erc20Contract);
        invoicesErc20.push(invoiceDataErc20);


        underlying.transferFrom(msg.sender, address(this), amount);
        
        //address sender, uint256 amount, bytes paymentReference, address supplier, address tokenAddress);
        emit PaymentInfoErc20(_erc20Contract, msg.sender, supplier, amount, dueDate, paymentReference);

        // Mint cTokens
        uint mintResult = cToken.mint(amount);
        return mintResult;
    }

      
    




    function transferAndSupplyErc20ToCompoundWithFee (
        address _erc20Contract,
        address _cErc20Contract,
        uint256 amount,
        address supplier,
        uint dueDate,
        bytes memory paymentReference,
        uint256 feeAmount,
        address feeReceiver
        ) public returns (uint) {
    
        // Create a reference to the underlying asset contract, like DAI.
        IErc20 underlying = IErc20(_erc20Contract);

        // Create a reference to the corresponding cToken contract, like cDAI
        CErc20 cToken = CErc20(_cErc20Contract);

        // Approve transfer on the ERC20 contract
        underlying.approve(_cErc20Contract, amount);

        dueDate = block.timestamp + (dueDate * 1 seconds);
        // feeAmount = (amount /1000 * 5);
        // feeReceiver = 0xF4255c5e53a08f72b0573D1b8905C5a50aA9c2De;
        address payable feeAddress = payable (feeReceiver);
        
        InvoiceErc20 memory invoiceDataErc20 = InvoiceErc20(amount, msg.sender, supplier, dueDate, paymentReference, _erc20Contract);
        invoicesErc20.push(invoiceDataErc20);
  
        underlying.transferFrom(msg.sender, address(this), (amount+feeAmount));
        (IErc20(_erc20Contract)).transfer(feeAddress, feeAmount);

        emit PaymentInfoErc20WithFee(_erc20Contract, supplier, amount, paymentReference, feeAmount, feeAddress );

        // Mint cTokens
        uint mintResult = cToken.mint(amount);
        return mintResult;
    }


    function returnInvoices() public view returns(Invoice[] memory) {
        return invoices;
    }

    function returnDueInvoices() public view returns(dueInvoice[] memory) {
        return dueInvoices;
    }

    function returnInvoicesErc20() public view returns(InvoiceErc20[] memory) {
        return invoicesErc20;
    }

    
    function returnDueInvoicesErc20() public view returns(dueInvoiceErc20[] memory) {
        return dueInvoicesErc20;
    }

   

    function redeemCEth(
        // address _suppliersAddress,
        uint256 amount,
        bool redeemType,
        address _cEtherContract
    ) public onlyOwner returns (bool) {
        // Create a reference to the corresponding cToken contract
        CEth cToken = CEth(_cEtherContract);

        // `amount` is scaled up by 1e18 to avoid decimals

        uint256 redeemResult;

        if (redeemType == true) {
            // Retrieve your asset based on a cToken amount
            redeemResult = cToken.redeem(amount);
           
        } else {
            // Retrieve your asset based on an amount of the asset
            redeemResult = cToken.redeemUnderlying(amount);
        }

        uint256 redeemedEth;

        if (redeemType == true) {
            uint exchangeRateMantissa = cToken.exchangeRateCurrent();
            redeemedEth =(amount * exchangeRateMantissa);
        }

        emit MyOwnLog("ETH redeemed :", redeemedEth);
        

        return true;
    }

    
    receive() external payable {}

     function redeemCErc20Tokens (
        uint256 amount,
        bool redeemType,
        address _cErc20Contract
    ) public onlyOwner returns (bool) {
        // Create a reference to the corresponding cToken contract, like cDAI
        CErc20 cToken = CErc20(_cErc20Contract);

        // `amount` is scaled up, see decimal table here:
        // https://compound.finance/docs#protocol-math

        uint256 redeemResult;

        if (redeemType == true) {
            // Retrieve your asset based on a cToken amount
            redeemResult = cToken.redeem(amount);
        } else {
            // Retrieve your asset based on an amount of the asset
            redeemResult = cToken.redeemUnderlying(amount);
        }

        // Error codes are listed here:
        // https://compound.finance/developers/ctokens#ctoken-error-codes
        emit MyLog("If this is not 0, there was an error", redeemResult);

        return true;
    }
    
    function payoutErc20(dueInvoiceErc20[] calldata invoicesFrontEnd) public onlyOwner {
        dueInvoiceErc20[] memory dueInvoicesErc20V2 = new dueInvoiceErc20[](invoicesFrontEnd.length);
        
        for (uint i = 0; i < invoicesFrontEnd.length; i++) {        
            
            uint256 _amount = invoicesFrontEnd[i].amount;
            uint256 _interestAmount = invoicesFrontEnd[i].interestAmount;
            address _sender = invoicesFrontEnd[i].sender;
            address _supplier = invoicesFrontEnd[i].supplier;
            uint48 _dueDate = invoicesFrontEnd[i].dueDate;
            bytes memory _paymentReference = invoicesFrontEnd[i].paymentReference;
            address  _tokenAddress = invoicesFrontEnd[i].tokenAddress;
            dueInvoicesErc20V2[i].amount = _amount;
            dueInvoicesErc20V2[i].interestAmount = _interestAmount;
            dueInvoicesErc20V2[i].sender = _sender;
            dueInvoicesErc20V2[i].supplier = _supplier;
            dueInvoicesErc20V2[i].dueDate = _dueDate;
            dueInvoicesErc20V2[i].paymentReference = _paymentReference;
            dueInvoicesErc20V2[i].tokenAddress = _tokenAddress;

            IErc20(dueInvoicesErc20V2[i].tokenAddress).transfer(dueInvoicesErc20V2[i].supplier, dueInvoicesErc20V2[i].amount);
            IErc20(dueInvoicesErc20V2[i].tokenAddress).transfer(dueInvoicesErc20V2[i].sender, dueInvoicesErc20V2[i].interestAmount);

            emit PayOutInfoErc20(_sender, _interestAmount, _supplier, _amount, _paymentReference, _dueDate, _tokenAddress);
            
        }
    }
    
   

    

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}