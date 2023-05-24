//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "./interface/ISFTRec.sol";
import "./interface/ICoreSFT_REC.sol";


interface helper {
    function price() external returns(uint256);
    function price(address) external returns(uint256);
    function maxDiscount() external returns(uint256);
    function maxDiscount(address) external returns(uint256);
}

/**
 * @title CoreSFT - Semi-Fungible Recommendation system.
 * @dev This contract is the core contract for the SFTRec, SFTJob and SFTInsignia usage.
 *         - It provides creation of recommendation discounts based on the previously deployed contracts that sells something.
 *         - 
 * @author Omnes - <Waiandt.eth>
 */


contract CoreSFT_REC is ICoreSFT_REC,Ownable, ERC1155Holder{
/// -----------------------------------------------------------------------
/// ---------------------------EVENTS--------------------------------------
/// -----------------------------------------------------------------------

event CreatedDiscountFromOwner(address indexed _material, address indexed _afiliate, uint256 indexed _calculatedDiscount);
event CreatedDiscountFromPrice(address indexed _material, address indexed _afiliate, uint256 indexed _calculatedDiscount);
event CreatedDiscountFromMapping(address indexed _material, address indexed _afiliate, uint256 indexed _calculatedDiscount);
event CreatedDiscount(address indexed _material, address indexed _afiliate, uint256 indexed _calculatedDiscount);
event AddedDiscountTokens(uint256 indexed _discountId, uint256 _amount);
event paymentHandled(uint256 indexed fullPrice, uint256 indexed discount, uint256 indexed payout);
event DiscountSet(address indexed _material, uint256 indexed _discount);


/// -----------------------------------------------------------------------
/// ---------------------------STORAGE-------------------------------------
/// -----------------------------------------------------------------------


ISFTRec private _SFTRec;
mapping (address => uint256) public acceptedTokensDecimals;
mapping (address => uint256) public discountSet;
mapping (uint256 => creationStruct) public publicSearch;
mapping(uint256 => uint256) public bag; //discountId => amount


/// -----------------------------------------------------------------------
/// -------------------------CONSTRUCTOR-----------------------------------
/// -----------------------------------------------------------------------

constructor() Ownable() ICoreSFT_REC(){
    acceptedTokensDecimals[0x0000000000000000000000000000000000000000] = 18;
}


/// -----------------------------------------------------------------------
/// ------------------------DISCOUNT FUNCTIONS-----------------------------
/// -----------------------------------------------------------------------


    function createDiscountFromOwner(creationStruct memory _params) public returns(uint256 discountID){
        _checkEOA();
        
        require((_params.creator =_params.materialOwner = Ownable(_params.material).owner()) != address(0), "Core SFT : Contract does not follow standard of ownership");
        
        if(_params.acceptedPayment != address(0))
        require(acceptedTokensDecimals[_params.acceptedPayment]>0,"Core SFT : Token not configured, check with the team");

        require(_params.creator == tx.origin,"Core SFT : Creator has to be the owner");
        require(_params.userDiscount < 10001, "Core SFT : Discount cannot be more than 100%");
        require(_params.fullPrice > 0 && _params.userDiscount > 0, "Core SFT : Value not set");
        require(_params.fullPrice < type(uint256).max/10000,"Core SFT : Full price will render an overflow on math");
        require(_params.amount > 0, "Core SFT : Amount of tickets bigger than 0");

        _params.recPayout = 0;
        discountID = _SFTRec.createDiscount(_params.amount, _params.metadata);
        publicSearch[discountID] = _params;

        emit CreatedDiscountFromOwner(_params.material, msg.sender, _calculateDiscount(_params));
    }
    function createDiscountFromPrice(creationStruct memory _params) public returns(uint256 discountID){
        _checkEOA();
        _params.creator = msg.sender;
        require((_params.materialOwner = Ownable(_params.material).owner()) != address(0), "Core SFT : Contract does not follow standard of ownership");
        require(_params.amount > 0, "Core SFT : Amount of tickets bigger than 0");
        if(_params.acceptedPayment != address(0))
        require(acceptedTokensDecimals[_params.acceptedPayment]>0,"Core SFT : Token not configured, check with the team");

        (bool success, bytes memory price) = _params.material.call(abi.encodeWithSignature("price()", ""));
        
        if(!success){
            revert("Core SFT : Sorry but only the owner can create through the function createDiscountFromOwner");

        }else if(bytesToUint(price) > 0){
            require(discountSet[_params.material] > 0, "Core SFT : Sorry, the owner of the material did not set a discount yet");
            require(_params.userDiscount <= discountSet[_params.material], "Core SFT : Discount cannot be more than set by the creator");
            if(msg.sender == _params.materialOwner)
                require(_params.recPayout == 0, "Core SFT : There is no comission allowed");
            else
                require(_params.recPayout < 10001, "Core SFT : Rec cannot take more than 100% of the discount");
            require(_params.userDiscount + _params.recPayout > _params.recPayout, "Core SFT : Cannot give payouts if there is no discount");
            _params.fullPrice = bytesToUint(price);
        }else{
            revert("Core SFT : Price on the material is not set yet");
        }

        discountID = _SFTRec.createDiscount(_params.amount, _params.metadata);
        publicSearch[discountID] = _params;

        emit CreatedDiscountFromPrice(_params.material, msg.sender, _calculateDiscount(_params));
    }
    function createDiscountFromMapping(creationStruct memory _params) public returns(uint256 discountID){
        _checkEOA();
        _params.creator = msg.sender;
        require((_params.materialOwner = Ownable(_params.material).owner()) != address(0), "Core SFT : Contract does not follow standard of ownership");
        require(_params.amount > 0, "Core SFT : Amount of tickets bigger than 0");

        if(_params.acceptedPayment != address(0))
        require(acceptedTokensDecimals[_params.acceptedPayment]>0,"Core SFT : Token not configured, check with the team");

        (bool success, bytes memory price) = _params.material.call(abi.encodeWithSignature("price(address)", _params.acceptedPayment));
        
        if(!success){
            revert("Core SFT : Sorry but only the owner can create through the function createDiscountFromOwner");

        }else if(bytesToUint(price) > 0){
            if(helper(_params.material).maxDiscount(_params.acceptedPayment) > 0){
                require(_params.userDiscount <= helper(_params.material).maxDiscount(_params.acceptedPayment), "Core SFT : Discount cannot be more than set by the contract");
            }else{
                require(_params.userDiscount <= 4000, "Core SFT : Discount cannot be more than 40%");
            }

            if(msg.sender == _params.materialOwner)
                require(_params.recPayout == 0, "Core SFT : There is no comission allowed");
            else
                require(_params.recPayout < 10001, "Core SFT : Rec cannot take more than 100% of the discount");
            require(_params.userDiscount + _params.recPayout > _params.recPayout, "Core SFT : Cannot give payouts if there is no discount");
            _params.fullPrice = bytesToUint(price);
        }else{
            revert("Core SFT : Price on the material is not set yet");
        }

        discountID = _SFTRec.createDiscount(_params.amount, _params.metadata);
        publicSearch[discountID] = _params;

        emit CreatedDiscountFromMapping(_params.material, msg.sender, _calculateDiscount(_params));
    }
    function createDiscount(creationStruct memory _params) public returns(uint256 discountID){
        _checkEOA();
        _params.creator = msg.sender;
        require((_params.materialOwner = Ownable(_params.material).owner()) != address(0), "Core SFT : Contract does not follow standard of ownership");
        require(_params.amount > 0, "Core SFT : Amount of tickets bigger than 0");

        if(_params.acceptedPayment != address(0))
        require(acceptedTokensDecimals[_params.acceptedPayment]>0,"Core SFT : Token not configured, check with the team");

        (bool success, bytes memory price) = _params.material.call(abi.encodeWithSignature("price()", ""));
        
        if(!success){
            revert("Core SFT : Sorry but only the owner can create through the function createDiscountFromOwner");
            
        }else if(bytesToUint(price) > 0){
            if(helper(_params.material).maxDiscount() > 0){
                require(_params.userDiscount <= helper(_params.material).maxDiscount(), "Core SFT : Discount cannot be more than set by the contract");
            }else{
                require(_params.userDiscount <= 4000, "Core SFT : Discount cannot be more than 40%");
            }
            
            if(msg.sender == _params.materialOwner)
                require(_params.recPayout == 0, "Core SFT : There is no comission allowed");
            else
                require(_params.recPayout < 10001, "Core SFT : Rec cannot take more than 100% of the discount");
            require(_params.userDiscount + _params.recPayout > _params.recPayout, "Core SFT : Cannot give payouts if there is no discount");
            _params.fullPrice = bytesToUint(price);
        }else{
            revert("Core SFT : Price on the material is not set yet");
        }

        discountID = _SFTRec.createDiscount(_params.amount, _params.metadata);
        publicSearch[discountID] = _params;

        emit CreatedDiscount(_params.material, msg.sender, _calculateDiscount(_params));
    }

    ///@dev unit test this
    function addBag(uint256 _discountId, uint256 _amount) public returns (bool){
        require(publicSearch[_discountId].creator == msg.sender, "Core SFT : Discount ID not valid or caller not the creator of the discount");

        _SFTRec.safeTransferFrom(msg.sender, address(this), _discountId, _amount, "");
        bag[_discountId] += _amount;

        return true;
    }

    function addDiscountTokens(uint256 _discountId, uint256 _amount) public returns (bool){
        require(publicSearch[_discountId].creator == msg.sender, "Core SFT : Discount ID not valid or caller not the creator of the discount");
        
        emit AddedDiscountTokens(_discountId, _amount);
        return _SFTRec.addDiscountTokens(_amount, _discountId);
    }


/// -----------------------------------------------------------------------
/// -------------------------REDEEMER MANAGER------------------------------
/// -----------------------------------------------------------------------

    // function redeem(uint256 _tokenId, bytes memory _callerParams) public  payable returns(bool){
    //     creationStruct memory _aux = publicSearch[_tokenId];

    //     require(_aux.creator != address(0), "Core SFT : Invalid tokenID");
        
    //     bool paid = _paymentHandler(_aux);

    //     require(paid, "Core SFT : Something went wrong with your payment");

    //     _SFTRec.redeemDiscount(_tokenId);

    //     // _redeemId(_aux, _callerParams);

    //     return _redeemId(_aux, _callerParams);


    // }

    function redeemFromBagSeparately(uint256 _tokenId,bool _bag, bytes calldata _callerParams) public payable returns(bool){
        _checkEOA();
        require(!_bag || bag[_tokenId] > 0, "Core SFT : There is no more bag discounts for that token");
        creationStruct memory _aux = publicSearch[_tokenId];
        
        _paymentHandler(_aux);

        _bag ? 
        _SFTRec.redeemBaggedDiscount(_tokenId) :
        _SFTRec.redeemDiscount(_tokenId);

        return _redeemId(_aux, _callerParams);


    }
    function redeemFromBagJoint(uint256 _tokenId,bool _bag, bytes calldata _callerParams) public payable returns(bool){
        _checkEOA();
        require(!_bag || bag[_tokenId] > 0, "Core SFT : There is no more bag discounts for that token");
        creationStruct memory _aux = publicSearch[_tokenId];
        
        // bool paid = _paymentHandler(_aux);

        _bag ? 
        _SFTRec.redeemBaggedDiscount(_tokenId) :
        _SFTRec.redeemDiscount(_tokenId);

        bool paid = _redeemIdJoint(_aux, _callerParams);
        require(paid, "Core SFT : Something went wrong with your payment");
        
        return true;


    }


/// -----------------------------------------------------------------------
/// -----------------------PARAMETERS FUNCTIONS----------------------------
/// -----------------------------------------------------------------------

    function fullPrice(uint256 _tokenId, uint256 _newPrice) public returns(uint256){
        creationStruct memory _aux = publicSearch[_tokenId];

        if(helper(publicSearch[_tokenId].material).price() > 0){
            revert("Core SFT : If the price changed on your contract, call update fullprice");
        }else{
        require(msg.sender == _aux.creator && msg.sender == _aux.materialOwner, "Core SFT : Cannot change params if you didn't create");
        require(_aux.fullPrice != _newPrice, "Core SFT : Cannot change to the same price");

        return publicSearch[_tokenId].fullPrice = _newPrice;
        }


    }

    function updateFullPrice(uint256 _tokenId) public returns(uint256){
        return publicSearch[_tokenId].fullPrice = helper(publicSearch[_tokenId].material).price();
    }

    function updateFullPriceMapped(uint256 _tokenId) public returns(uint256){
        creationStruct memory _aux = publicSearch[_tokenId];
        return publicSearch[_tokenId].fullPrice = helper(_aux.material).price(_aux.acceptedPayment);
    }

    ///@dev check this functionality because it doesn't make sense to have
    function userDiscount(uint256 _tokenId,uint24 _userDiscount, string memory _metadata) public returns(string memory){
        creationStruct memory _aux = publicSearch[_tokenId];
        if(helper(publicSearch[_tokenId].material).price() > 0){
            require(msg.sender == _aux.creator, "Core SFT : Only the creator can change the discount");
            _aux.userDiscount = _userDiscount;
            return publicSearch[_tokenId].metadata = _metadata;
        }else{
            require(msg.sender == _aux.materialOwner, "Core SFT : Only the owner can change the discount");
            require(_userDiscount != _aux.userDiscount || keccak256(abi.encode(_metadata)) != keccak256(abi.encode(_aux.metadata)), "Core SFT : It seems you don't have params to change");
            require(_userDiscount <= 4000 || _userDiscount < helper(publicSearch[_tokenId].material).maxDiscount(), "Core SFT : Discount cannot be more than 40%");
            publicSearch[_tokenId].userDiscount = _userDiscount;
            return publicSearch[_tokenId].metadata = _metadata;
        }
    }
    function acceptedPayment(uint256 _tokenId,address _newPaymentToken) public returns(address){
        require(msg.sender == publicSearch[_tokenId].creator,"Core SFT : Only the creator can change the payout");
        require(acceptedTokensDecimals[_newPaymentToken] > 0, "Core SFT : Token not configured, check with the team");

        return publicSearch[_tokenId].acceptedPayment = _newPaymentToken;
    }
    function funcSelector(uint256 _tokenId, bytes4 _newFuncSelector) public returns(bytes4){
        require(msg.sender == publicSearch[_tokenId].creator,"Core SFT : Only the creator can change the payout");
        
        return publicSearch[_tokenId].funcSelector = _newFuncSelector;
    }



/// -----------------------------------------------------------------------
/// ---------------------------SET FUNCTIONS-------------------------------
/// -----------------------------------------------------------------------


    function setAcceptedToken(address _token) public onlyOwner {
        (bool success , bytes memory _data) = _token.call(abi.encodeWithSignature("decimals()", ""));
        require(success, "SFTRec : Token does not have decimals");
        acceptedTokensDecimals[_token] = bytesToUint(_data);
    }

    function setSFTRec(address __SFTRec) public onlyOwner {
        _SFTRec = ISFTRec(__SFTRec);
    }

    function setDiscount(address _material, uint256 _discount) public {
        require(Ownable(_material).owner() == msg.sender, "Core SFT : Only the material owner can set the discount");
        require(_discount > 99 && _discount < 10001, "Core SFT : Please keep the discount between 1 and 100 %");

        discountSet[_material] = _discount;
        emit DiscountSet(_material, _discount);
    }

/// -----------------------------------------------------------------------
/// ---------------------------GET FUNCTIONS-------------------------------
/// -----------------------------------------------------------------------

    function fullPrice(uint256 _tokenId) public view returns (uint256){
        return publicSearch[_tokenId].fullPrice;
    }

    // function getSFTRec() public view returns(address){
    //     return address(_SFTRec);
    // }



/// -----------------------------------------------------------------------
/// -------------------------INTERNAL FUNCTIONS----------------------------
/// -----------------------------------------------------------------------

    function _paymentHandler(creationStruct memory _aux) internal virtual returns (uint256 _initialUserDiscount){
        
        _initialUserDiscount = (_aux.fullPrice * (10000 - _aux.userDiscount))/10000;
        uint256 _creatorPayout = ((_aux.fullPrice - (_initialUserDiscount)) * _aux.recPayout)/10000;
        uint256 _price = _initialUserDiscount + _creatorPayout;

        if(_aux.acceptedPayment == address(0)){
            require(msg.value == _price, "Core SFT : Value sent does not match the price");
            payable(_aux.material).transfer(_initialUserDiscount);
            payable(_aux.creator).transfer(_creatorPayout);

            
        }else{
            require(msg.value == 0, "Core SFT : Sent value in ether is not necessary");
                require(IERC20(_aux.acceptedPayment).allowance(msg.sender, address(this)) >= _price, "Core SFT : User allowance not enough");
                IERC20(_aux.acceptedPayment).transferFrom(msg.sender, address(this), _price);
                IERC20(_aux.acceptedPayment).transfer(_aux.material, _initialUserDiscount);
                IERC20(_aux.acceptedPayment).transfer(_aux.creator, _creatorPayout);
        }

        emit paymentHandled(_aux.fullPrice, _aux.userDiscount, _aux.recPayout);

    }

    function _calculateDiscount(creationStruct memory _aux) internal pure returns (uint256){
        uint256 _initialUserDiscount = (_aux.fullPrice * (10000 - _aux.userDiscount))/10000;
        uint256 _creatorPayout = ((_aux.fullPrice - _initialUserDiscount) * _aux.recPayout)/10000;
        uint256 _price = _initialUserDiscount + _creatorPayout;

        return((_price*100)/_aux.fullPrice);
    }

    function _redeemId(creationStruct memory _aux,bytes calldata _callerParams) internal returns (bool){
        if(_aux.funcSelector != bytes4(0)){
            require(_func(_callerParams) == _aux.funcSelector, "Core SFT : _callerParams not matching encodeWithSignature");
            (bool success,) = _aux.material.call(_callerParams);
            require(success,"Core SFT : Something went wrong with the redeem, please check inputs");
        }else{
            uint256 _token = bytesToUint(_callerParams);

            (bool redeemed,) = _aux.material.call(abi.encodeWithSelector(0x731133e9, msg.sender,_token,1,""));//1155
            
            if(!redeemed){
                (redeemed,) = _aux.material.call(abi.encodeWithSignature("mint(address,uint256)", msg.sender,_token));
                require (redeemed, "Core SFT : None of the redeem trials seems to work, please check params and function calls");
            }
        } 

        return true;  
    }
    function _redeemIdJoint(creationStruct memory _aux,bytes calldata _callerParams) internal returns (bool){
        uint256 _initialUserDiscount = (_aux.fullPrice * (10000 - _aux.userDiscount))/10000;
        uint256 _creatorPayout = ((_aux.fullPrice - _initialUserDiscount) * _aux.recPayout)/10000;
        uint256 _price = _initialUserDiscount + _creatorPayout;

        if(_aux.funcSelector != bytes4(0)){
            if(_aux.acceptedPayment == address(0)){
                require(_func(_callerParams) == _aux.funcSelector, "Core SFT : _callerParams not matching encodeWithSignature");
                (bool success,) = _aux.material.call{value : _initialUserDiscount}(_callerParams);
                require(success,"Core SFT : Something went wrong with the redeem, please check inputs");
                payable(_aux.creator).transfer(_creatorPayout);
            }else{
                require(msg.value == 0, "Core SFT : Sent value in ether is not necessary");
                require(IERC20(_aux.acceptedPayment).allowance(msg.sender, address(this)) >= _price, "Core SFT : User allowance not enough");
                IERC20(_aux.acceptedPayment).transferFrom(msg.sender, address(this), _price);
                require(_func(_callerParams) == _aux.funcSelector, "Core SFT : _callerParams not matching encodeWithSignature");
                (bool success,) = _aux.material.call{value : _initialUserDiscount}(_callerParams);
                require(success,"Core SFT : Something went wrong with the redeem, please check inputs");
                IERC20(_aux.acceptedPayment).transfer(_aux.creator, _creatorPayout);
            }
        }else{
            uint256 _token = bytesToUint(_callerParams);
            if(_aux.acceptedPayment == address(0)){
                (bool redeemed,) = _aux.material.call{value: _initialUserDiscount}(abi.encodeWithSelector(0x731133e9, msg.sender,_token,1,""));//1155
            
                if(!redeemed){
                    (redeemed,) = _aux.material.call{value: _initialUserDiscount}(abi.encodeWithSignature("mint(address,uint256)", msg.sender,_token));
                    require (redeemed, "Core SFT : None of the redeem trials seems to work, please check params and function calls");
                }
                payable(_aux.creator).transfer(_creatorPayout);
            }else{
                require(msg.value == 0, "Core SFT : Sent value in ether is not necessary");
                require(IERC20(_aux.acceptedPayment).allowance(msg.sender, address(this)) >= _price, "Core SFT : User allowance not enough");
                IERC20(_aux.acceptedPayment).transferFrom(msg.sender, address(this), _price);
                (bool redeemed,) = _aux.material.call(abi.encodeWithSelector(0x731133e9, msg.sender,_token,1,""));//1155
            
                if(!redeemed){
                    (redeemed,) = _aux.material.call(abi.encodeWithSignature("mint(address,uint256)", msg.sender,_token));
                    require (redeemed, "Core SFT : None of the redeem trials seems to work, please check params and function calls");
                }
                IERC20(_aux.acceptedPayment).transfer(_aux.creator, _creatorPayout);
            }
        } 

        return true;  
    }

    function _checkEOA() private view{
        require(msg.sender == tx.origin, "Core SFT : No contract calls here");
    }


    function bytesToUint(bytes memory b) internal pure returns (uint256){
        uint256 number;
        for(uint i=0;i<b.length;i++){
            number = number + uint(uint8(b[i]))*(2**(8*(b.length-(i+1))));
        }
        return number;
    }

    function _func(bytes calldata data) internal pure returns(bytes4 selector) {
        selector = bytes4(data[:4]);
    }




    ///@dev CREATE SOULBOUND INSIGNIA FOR USER TECNOLOGY AND USER RECOMMENDATION PROGRAM
    ///@dev CREATE A POSSIBILITY FOR SMALL UNIT CHALLENGES TO EARN THE INSIGNIA FROM THE PROTOCOL
    ///@dev CREATE A JOB HUNT PAGE AND A USER MATCH SYSTEM



}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

interface ISFTRec {
    function currentId() external returns(uint256);
    
    // function price() external returns(uint256);

    // function maxDiscount() external returns(uint256);

    function createDiscount(uint256 _amount, string memory _tokenURI) external returns(uint256);

    function addDiscountTokens(uint256 _amount, uint256 _id) external returns (bool);

    function redeemDiscount(uint256 _id) external returns (bool);

    function redeemBaggedDiscount(uint256 _id) external returns (bool);

    // function mint(address to, uint256 tokenId) external returns (bool); // 721
    
    // function mint(address to, uint256 tokenId, uint256 amount, bytes memory data) external returns (bool); // 1155

    function setURI(uint _tokenId, string memory _tokenURI) external;

    function setBaseUri(string memory _baseURI) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;


interface ICoreSFT_REC{


// CREATE USER INPUT CREATION
// CREATE GET ACCEPTED TOKEN

///@dev This is the struct used to create discount tokens
///@param creator is the discount creator
///@param material is the address of the material that receives the payment and mints the asset
///@param fullPrice is the price without discount set on the origin contract
///@param userDiscount is the discount provided for the user
///@param recPayout is the amount paid for the afiliate
///@param acceptedPayment is the address of the payment token //CHECK THIS SECURITY BREACH
///@param funcSelector is used in the case of custom mint functions that do not follow the standards
///@param metadata is the tokenURI of that discount
///@param materialOwner is the owner of the contract that has the mint function
///@param amount is the amount of discount tokens to be minted
struct creationStruct{
    address creator;
    address material;
    uint256 fullPrice;
    uint24 userDiscount;
    uint24 recPayout;
    address acceptedPayment;
    bytes4 funcSelector;
    string metadata;
    address materialOwner;
    uint256 amount;
}

/// -----------------------------------------------------------------------
/// ------------------------DISCOUNT FUNCTIONS-----------------------------
/// -----------------------------------------------------------------------

///@dev Create a disicount with neither price nor macDiscount only by the material owner
function createDiscountFromOwner(creationStruct memory _params) external  returns(uint256 discountID);

///@dev Create a disicount with only the price and no maxDiscount
///@notice The material owner has to set a maxDiscount in the coreSFT contract
function createDiscountFromPrice(creationStruct memory _params) external  returns(uint256 discountID);

///@dev Create a discount based on a mapped price and mapped discount
function createDiscountFromMapping(creationStruct memory _params) external  returns(uint256 discountID);

///@dev Creates a discount based on general user 
function createDiscount(creationStruct memory _params) external  returns(uint256 discountID);

///@dev Adds discount tokens to a specific id
///@notice only the discount creator can add tokens
///@param _discountId is the id of the token created
///@param _amount is the amount of new tokens
function addDiscountTokens(uint256 _discountId, uint256 _amount) external returns (bool);

/// -----------------------------------------------------------------------
/// -------------------------REDEEMER MANAGER------------------------------
/// -----------------------------------------------------------------------

///@dev Redeems the item based on the discount id
///@param _tokenId is the id of the discount token
///@param _bag , if you do not have a discount SFT you can try to get from the public bag by inputting TRUE
///@param _callerParams are the params considering a custom function call
function redeemFromBagSeparately(uint256 _tokenId,bool _bag, bytes memory _callerParams) external  payable returns(bool);

/// -----------------------------------------------------------------------
/// -----------------------PARAMETERS FUNCTIONS----------------------------
/// -----------------------------------------------------------------------

///@dev Sets a new fullPrice for the discount
///@notice only the material owner can do that since only the owner can create a discount with no price on the contract
///@param _tokenId is the discount token id
///@param _newPrice is the new price for that material
function fullPrice(uint256 _tokenId, uint256 _newPrice) external  returns(uint256);

///@dev Updates a full price
///@notice Anyone can call that if the material has a price variable
///@param _tokenId is the discount token id
function updateFullPrice(uint256 _tokenId) external returns(uint256);


///@dev Updates a full price on a mapped contract
///@notice Anyone can call that if the material has a price variable
///@param _tokenId is the discount token id
function updateFullPriceMapped(uint256 _tokenId) external returns(uint256);

function userDiscount(uint256 _tokenId,uint24 _userDiscount, string memory _metadata) external returns(string memory); // on trial

///@dev Sets a new payout for the recommender
///@notice only the discount creator can change
///@param _tokenId is the discount token id
///@param _payout is the new payout and has to be =< 10000 (100%)
///@param _metadata is the new tokenURI metadata
// function recPayout(uint256 _tokenId,uint24 _payout, string memory _metadata) external  returns(uint256 _rec);

///@dev Sets a new accepted token
///@notice only the discount creator can change
///@param _tokenId is the discount token id
///@param _newPaymentToken is the new accepted token
function acceptedPayment(uint256 _tokenId,address _newPaymentToken) external  returns(address);

///@dev Sets a new function selector
///@notice only the discount creator can change
///@param _tokenId is the discount token id
///@param _newFuncSelector is the new function selector
function funcSelector(uint256 _tokenId, bytes4 _newFuncSelector) external  returns(bytes4);



/// -----------------------------------------------------------------------
/// ---------------------------SET FUNCTIONS-------------------------------
/// -----------------------------------------------------------------------

///@dev Sets a discount for a contract with only price
///@notice Only the material Owner can do that
///@param _material is the address of the material contract
///@param _discount is the discount to be set
function setDiscount(address _material, uint256 _discount) external;


/// -----------------------------------------------------------------------
/// ---------------------------GET FUNCTIONS-------------------------------
/// -----------------------------------------------------------------------

///@dev Returns the full price of a discount
///@param _tokenId is the discount token id
// function fullPrice(uint256 _tokenId) external view returns (uint256);








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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}