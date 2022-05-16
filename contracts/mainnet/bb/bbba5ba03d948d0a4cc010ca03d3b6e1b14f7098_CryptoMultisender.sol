/**
 *Submitted for verification at Etherscan.io on 2022-05-16
*/

pragma solidity ^0.8.0;
 

contract Ownable {
    
    address public owner;
    
    event OwnershipTransferred(address indexed from, address indexed to);
    
    /**
     * Constructor assigns ownership to the address used to deploy the contract.
     * */
    constructor() {
        owner = msg.sender;
    }

    function getOwner() public view returns(address) {
        return owner;
    }

    /**
     * Any function with this modifier in its method signature can only be executed by
     * the owner of the contract. Any attempt made by any other account to invoke the 
     * functions with this modifier will result in a loss of gas and the contract's state
     * will remain untampered.
     * */
    modifier onlyOwner {
        require(msg.sender == owner, "Function restricted to owner of contract");
        _;
    }

    /**
     * Allows for the transfer of ownership to another address;
     * 
     * @param _newOwner The address to be assigned new ownership.
     * */
    function transferOwnership(address _newOwner) public onlyOwner {
        require(
            _newOwner != address(0)
            && _newOwner != owner 
        );
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}



abstract contract DeprecatedMultisenderSC {
    function isPremiumMember(address _who) external virtual view returns(bool);
}

/**
 * Contract acts as an interface between the Crypto Multisender contract and all ERC20 compliant
 * tokens. 
 * */
abstract contract ERC20Interface {
    function transferFrom(address _from, address _to, uint256 _value) public virtual;
    function balanceOf(address who)  public virtual returns (uint256);
    function allowance(address owner, address spender)  public view virtual returns (uint256);
    function transfer(address to, uint256 value) public virtual returns(bool);
    function gasOptimizedAirdrop(address[] calldata _addrs, uint256[] calldata _values) external virtual; 
}

/**
 * Contract acts as an interface between the NFT Crypto Multisender contract and all ERC721 compliant
 * tokens. 
 * */
abstract contract ERC721Interface {
    function transferFrom(address _from, address _to, uint256 _tokenId) public virtual;
    function balanceOf(address who)  public virtual returns (uint256);
    function isApprovedForAll(address _owner, address _operator) public view virtual returns(bool);
    function setApprovalForAll(address _operator, bool approved) public virtual;
    function gasOptimizedAirdrop(address _invoker, address[] calldata _addrs, uint256[] calldata _tokenIds) external virtual;
}


/**
 * Contract acts as an interface between the NFT Crypto Multisender contract and all ERC1155 compliant
 * tokens. 
 * */
abstract contract ERC1155Interface {
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, uint256 _amount, bytes memory data) public virtual;
    function balanceOf(address _who, uint256 _id)  public virtual returns (uint256);
    function isApprovedForAll(address _owner, address _operator) public view virtual returns(bool);
    function setApprovalForAll(address _operator, bool approved) public virtual;
    function gasOptimizedAirdrop(address _invoker, address[] calldata _addrs, uint256[] calldata _tokenIds, uint256[] calldata _amounts) external virtual;
}



contract CryptoMultisender is Ownable {
 
    mapping (address => uint256) public tokenTrialDrops;
    mapping (address => uint256) public userTrialDrops;

    mapping (address => uint256) public premiumMembershipDiscount;
    mapping (address => uint256) public membershipExpiryTime;

    mapping (address => bool) public isGrantedPremiumMember;

    mapping (address => bool) public isListedToken;
    mapping (address => uint256) public tokenListingFeeDiscount;

    mapping (address => bool) public isGrantedListedToken;

    mapping (address => bool) public isAffiliate;
    mapping (string => address) public affiliateCodeToAddr;
    mapping (string => bool) public affiliateCodeExists;
    mapping (address => string) public affiliateCodeOfAddr;
    mapping (address => string) public isAffiliatedWith;
    mapping (string => uint256) public commissionPercentage;

    uint256 public oneDayMembershipFee;
    uint256 public sevenDayMembershipFee;
    uint256 public oneMonthMembershipFee;
    uint256 public lifetimeMembershipFee;
    uint256 public tokenListingFee;
    uint256 public rate;
    uint256 public dropUnitPrice;
    address public deprecatedMultisenderAddress;

    event TokenAirdrop(address indexed by, address indexed tokenAddress, uint256 totalTransfers);
    event EthAirdrop(address indexed by, uint256 totalTransfers, uint256 ethValue);
    event NftAirdrop(address indexed by, address indexed nftAddress, uint256 totalTransfers);
    event RateChanged(uint256 from, uint256 to);
    event RefundIssued(address indexed to, uint256 totalWei);
    event ERC20TokensWithdrawn(address token, address sentTo, uint256 value);
    event CommissionPaid(address indexed to, uint256 value);
    event NewPremiumMembership(address indexed premiumMember);
    event NewAffiliatePartnership(address indexed newAffiliate, string indexed affiliateCode);
    event AffiliatePartnershipRevoked(address indexed affiliate, string indexed affiliateCode);
    
    constructor() {
        rate = 3000;
        dropUnitPrice = 333333333333333; 
        oneDayMembershipFee = 9e17;
        sevenDayMembershipFee = 125e16;
        oneMonthMembershipFee = 2e18;
        lifetimeMembershipFee = 25e17;
        tokenListingFee = 5e18;
        deprecatedMultisenderAddress=address(0xF521007C7845590C6c5ae46833DEFa0A68883CD4);
    }

    /**
     * Allows the owner of this contract to change the fees for users to become premium members.
     * 
     * @param _oneDayFee Fee for single day membership.
     * @param _sevenDayFee Fee for one week membership.
     * @param _oneMonthFee Fee for one month membership.
     * @param _lifetimeFee Fee for lifetime membership.
     * 
     * @return success True if the fee is changed successfully. False otherwise.
     * */
    function setMembershipFees(uint256 _oneDayFee, uint256 _sevenDayFee, uint256 _oneMonthFee, uint256 _lifetimeFee) public onlyOwner returns(bool success) {
        require(_oneDayFee>0 && _oneDayFee<_sevenDayFee && _sevenDayFee<_oneMonthFee && _oneMonthFee<_lifetimeFee);
        oneDayMembershipFee = _oneDayFee;
        sevenDayMembershipFee = _sevenDayFee;
        oneMonthMembershipFee = _oneMonthFee;
        lifetimeMembershipFee = _lifetimeFee;
        return true;
    }

    /**
     * Allows for the conversion of an unsigned integer to a string value. 
     * 
     * @param _i The value of the unsigned integer
     * 
     * @return _uintAsString The string value of the unsigned integer.
     * */
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    /**
    * Used to give change to users who accidentally send too much ETH to payable functions. 
    *
    * @param _price The service fee the user has to pay for function execution. 
    **/
    function giveChange(uint256 _price) internal {
        if(msg.value > _price) {
            uint256 change = msg.value - _price;
            payable(msg.sender).transfer(change);
        }
    }
    
    /**
    * Ensures that the correct affiliate code is used and also ensures that affiliate partners
    * are not able to 'jack' commissions from existing users who they are not affiliated with. 
    *
    * @param _afCode The affiliate code provided by the user.
    *
    * @return code The correct affiliate code or void.
    **/
    function processAffiliateCode(string memory _afCode) internal returns(string memory code) {
        if(stringsAreEqual(isAffiliatedWith[msg.sender], "void") || !isAffiliate[affiliateCodeToAddr[_afCode]]) {
            isAffiliatedWith[msg.sender] = "void";
            return "void";
        }
        if(!stringsAreEqual(_afCode, "") && stringsAreEqual(isAffiliatedWith[msg.sender],"") 
                                                                && affiliateCodeExists[_afCode]) {
            if(affiliateCodeToAddr[_afCode] == msg.sender) {
                return "void";
            }
            isAffiliatedWith[msg.sender] = _afCode;
        }
        if(stringsAreEqual(_afCode,"") && !stringsAreEqual(isAffiliatedWith[msg.sender],"")) {
            _afCode = isAffiliatedWith[msg.sender];
        } 
        if(stringsAreEqual(_afCode,"") || !affiliateCodeExists[_afCode]) {
            isAffiliatedWith[msg.sender] = "void";
            _afCode = "void";
        }
        return _afCode;
    }

    /**
     * Allows users to check if a user is a premium member or not. 
     * 
     * @param _addr The address of the user. 
     * 
     * @return isMember True if the user is a premium member, false otherwise.
     * */
    function checkIsPremiumMember(address _addr) public view returns(bool isMember) {
        return membershipExpiryTime[_addr] >= block.timestamp || isGrantedPremiumMember[_addr];
    }

    /**
    * Allows the owner of this contract to grant users with premium membership.
    *
    * @param _addr The address of the user who is being granted premium membership.
    *
    * @return success True if premium membership is granted successfully. False otherwise. 
    **/
    function grantPremiumMembership(address _addr) public onlyOwner returns(bool success) {
        require(checkIsPremiumMember(_addr) != true, "Is already premiumMember member");
        isGrantedPremiumMember[_addr] = true;
        emit NewPremiumMembership(_addr);
        return true; 
    }

    /**
    * Allows the owner of this contract to revoke a granted membership.
    *
    * @param _addr The address of the user whos membership is being revoked.
    *
    * @return success True if membership is revoked successfully. False otherwise. 
    **/
    function revokeGrantedPremiumMembership(address _addr) public onlyOwner returns(bool success) {
        require(isGrantedPremiumMember[_addr], "Not a granted membership");
        isGrantedPremiumMember[_addr] = false;
        return true;
    }

    /**
     * Allows the owner of the contract to grant a premium membership discount for a specified user.
     * 
     * @param _addr The address of the user.
     * @param _discount The discount being granted.
     * 
     * @return success True if function executes successfully, false otherwise.
     * */
    function setPremiumMembershipDiscount(address _addr, uint256 _discount) public onlyOwner returns(bool success) {
        premiumMembershipDiscount[_addr] = _discount;
        return true;
    }

    /**
     * Allows users to check VIP membership fees for a specific address. This is useful for validating if a discount
     * has been granted for the specified user. 
     * 
     * @param _addr The address of the user.
     * @param _fee The default fee. 
     * 
     * @return fee The membership fee for the specified user. 
     * 
     * */
    function getPremiumMembershipFeeOfUser(address _addr, uint256 _fee) public view returns(uint256 fee) {
        if(premiumMembershipDiscount[_addr] > 0) {
            return _fee * premiumMembershipDiscount[_addr] / 100;
        }
        return _fee;
    }



    /**
     * Allows the owner of the contract to set the contract address of the old multisender SC.
     * 
     * @param _addr The updated address.
     * */
    function setDeprecatedMultisenderAddress(address _addr) public onlyOwner {
        deprecatedMultisenderAddress = _addr;
    }


    /**
     * This function checks if a user address has a membership on the old SC.
     * 
     * @param _who The address of the user.
     * 
     * @return True if the user is a member on the old SC, false otherwise.
     * */
    function isMemberOfOldMultisender(address _who) public view returns(bool) {
        DeprecatedMultisenderSC oldMultisender = DeprecatedMultisenderSC(deprecatedMultisenderAddress);
        return oldMultisender.isPremiumMember(_who);
    }


    /**
     * Allows users to transfer their membership from the old SC to this SC. 
     * 
     * @return True if there is a membership to be transferred, false otherwise. 
     * */
    function transferMembership() public returns(bool) {
        require(isMemberOfOldMultisender(msg.sender), "No membership to transfer");
        membershipExpiryTime[msg.sender] = block.timestamp + (36500 * 1 days);
        return true;
    }
    

    /**
     * This function is invoked internally the functions for purchasing memberships.
     * 
     * @param _days The number of days that the membership will be valid for. 
     * @param _fee The fee that is to be paid. 
     * @param _afCode If a user has been refferred by an affiliate partner, they can provide 
     * an affiliate code so the partner gets commission.
     * 
     * @return success True if function executes successfully, false otherwise.
     * */
    function assignMembership(uint256 _days, uint256 _fee, string memory _afCode) internal returns(bool success) {
        require(checkIsPremiumMember(msg.sender) != true, "Is already premiumMember member");
        uint256 fee = getPremiumMembershipFeeOfUser(msg.sender, _fee);
        require(
            msg.value >= fee,
            string(abi.encodePacked(
                "premiumMember fee is: ", uint2str(fee), ". Not enough funds sent. ", uint2str(msg.value)
            ))
        );
        membershipExpiryTime[msg.sender] = block.timestamp + (_days * 1 days);
        _afCode = processAffiliateCode(_afCode);
        giveChange(fee);
        distributeCommission(fee, _afCode);
        emit NewPremiumMembership(msg.sender);
        return true; 
    }

    /**
    * Allows users to become lifetime members.
    *
    * @param _afCode If a user has been refferred by an affiliate partner, they can provide 
    * an affiliate code so the partner gets commission.
    *
    * @return success True if user successfully becomes premium member. False otherwise. 
    **/
    function becomeLifetimeMember(string memory _afCode) public payable returns(bool success) {
        assignMembership(36500, lifetimeMembershipFee, _afCode);
        return true;
    }


    /**
    * Allows users to become members for 1 day.
    *
    * @param _afCode If a user has been refferred by an affiliate partner, they can provide 
    * an affiliate code so the partner gets commission.
    *
    * @return success True if user successfully becomes premium member. False otherwise. 
    **/
    function becomeOneDayMember(string memory _afCode) public payable returns(bool success) {
        assignMembership(1, oneDayMembershipFee, _afCode);
        return true;
    }


    /**
    * Allows users to become members for 7 days.
    *
    * @param _afCode If a user has been refferred by an affiliate partner, they can provide 
    * an affiliate code so the partner gets commission.
    *
    * @return success True if user successfully becomes premium member. False otherwise. 
    **/
    function becomeOneWeekMember(string memory _afCode) public payable returns(bool success) {
        assignMembership(7, sevenDayMembershipFee, _afCode);
        return true;
    }


    /**
    * Allows users to become members for 1 month
    *
    * @param _afCode If a user has been refferred by an affiliate partner, they can provide 
    * an affiliate code so the partner gets commission.
    *
    * @return success True if user successfully becomes premium member. False otherwise. 
    **/
    function becomeOneMonthMember(string memory _afCode) public payable returns(bool success) {
        assignMembership(31, oneMonthMembershipFee, _afCode);
        return true;
    }


    /**
     * Allows users to check whether or not a token is listed.
     * 
     * @param _tokenAddr The address of the token to query.
     * 
     * @return isListed True if the token is listed, false otherwise. 
     * */
    function checkIsListedToken(address _tokenAddr) public view returns(bool isListed) {
        return isListedToken[_tokenAddr] || isGrantedListedToken[_tokenAddr];
    }


    /**
     * Allows the owner of the contract to set a listing discount for a specified token.
     * 
     * @param _tokenAddr The address of the token that will receive the discount. 
     * @param _discount The discount that will be applied. 
     * 
     * @return success True if function executes successfully, false otherwise.
     * */
    function setTokenListingFeeDiscount(address _tokenAddr, uint256 _discount) public onlyOwner returns(bool success) {
        tokenListingFeeDiscount[_tokenAddr] = _discount;
        return true;
    }

    /**
     * Allows users to query the listing fee for a token. This is useful to verify that a discount has been set. 
     * 
     * @param _tokenAddr The address of the token. 
     * 
     * @return fee The listing fee for the token. 
     * */
    function getListingFeeForToken(address _tokenAddr) public view returns(uint256 fee) {
        if(tokenListingFeeDiscount[_tokenAddr] > 0) {
            return tokenListingFee * tokenListingFeeDiscount[_tokenAddr] / 100;
        }
        return tokenListingFee;
    }

    /**
     * Allows users to list a token of their choosing. 
     * 
     * @param _tokenAddr The address of the token that will be listed. 
     * @param _afCode If the user is affiliated with a partner, they will provide this code so that 
     * the parter is paid commission.
     * 
     * @return success True if function executes successfully, false otherwise.
     * */
    function purchaseTokenListing(address _tokenAddr, string memory _afCode) public payable returns(bool success) {
        require(!checkIsListedToken(_tokenAddr), "Token is already listed");
        _afCode = processAffiliateCode(_afCode);
        uint256 fee = getListingFeeForToken(_tokenAddr);
        require(msg.value >= fee, "Not enough funds sent for listing");
        isListedToken[_tokenAddr] = true;
        giveChange(fee);
        distributeCommission(fee, _afCode);
        return true;
    }

    /**
     * Allows the owner of the contract to revoke a granted token listing. 
     * 
     * @param _tokenAddr The address of the token that is being delisted. 
     * 
     * @return success True if function executes successfully, false otherwise.
     * */
    function revokeGrantedTokenListing(address _tokenAddr) public onlyOwner returns(bool success) {
        require(checkIsListedToken(_tokenAddr), "Is not listed token");
        isGrantedListedToken[_tokenAddr] = false;
        return  true;
    }


    /**
     * Allows the owner of the contract to grant a token a free listing. 
     * 
     * @param _tokenAddr The address of the token being listed.
     * 
     * @return success True if function executes successfully, false otherwise.
     * */
    function grantTokenListing(address _tokenAddr) public onlyOwner returns(bool success){
        require(!checkIsListedToken(_tokenAddr), "Token is already listed");
        isGrantedListedToken[_tokenAddr] = true;
        return true;
    }

    /**
     * Allows the owner of the contract to modify the token listing fee. 
     * 
     * @param _newFee The new fee for token listings. 
     * 
     * @return success True if function executes successfully, false otherwise.
     * */
    function setTokenListingFee(uint256 _newFee) public onlyOwner returns(bool success){
        tokenListingFee = _newFee;
        return true;
    }
    
    /**
    * Allows the owner of this contract to add an affiliate partner.
    *
    * @param _addr The address of the new affiliate partner.
    * @param _code The affiliate code.
    * 
    * @return success True if the affiliate has been added successfully. False otherwise. 
    **/
    function addAffiliate(address _addr, string memory _code, uint256 _percentage) public onlyOwner returns(bool success) {
        require(!isAffiliate[_addr], "Address is already an affiliate.");
        require(_addr != address(0), "0x00 address not allowed");
        require(!affiliateCodeExists[_code], "Affiliate code already exists!");
        require(_percentage <= 100 && _percentage > 0, "Percentage must be > 0 && <= 100");
        affiliateCodeExists[_code] = true;
        isAffiliate[_addr] = true;
        affiliateCodeToAddr[_code] = _addr;
        affiliateCodeOfAddr[_addr] = _code;
        commissionPercentage[_code] = _percentage;
        emit NewAffiliatePartnership(_addr,_code);
        return true;
    }


    /**
     * Allows the owner of the contract to set a customised commission percentage for a given affiliate partner.
     * 
     * @param _addressOfAffiliate The wallet address of the affiliate partner.
     * @param _percentage The commission percentage the affiliate will receive.
     * 
     * @return success True if function executes successfully, false otherwise.
     * */
    function changeAffiliatePercentage(address _addressOfAffiliate, uint256 _percentage) public onlyOwner returns(bool success) { 
        require(isAffiliate[_addressOfAffiliate]);
        string storage affCode = affiliateCodeOfAddr[_addressOfAffiliate];
        commissionPercentage[affCode] = _percentage;
        return true;
    }

    /**
    * Allows the owner of this contract to remove an affiliate partner. 
    *
    * @param _addr The address of the affiliate partner.
    *
    * @return success True if affiliate partner is removed successfully. False otherwise. 
    **/
    function removeAffiliate(address _addr) public onlyOwner returns(bool success) {
        require(isAffiliate[_addr]);
        isAffiliate[_addr] = false;
        affiliateCodeToAddr[affiliateCodeOfAddr[_addr]] = address(0);
        emit AffiliatePartnershipRevoked(_addr, affiliateCodeOfAddr[_addr]);
        affiliateCodeOfAddr[_addr] = "No longer an affiliate partner";
        return true;
    }
    
    /**
     * Checks whether or not an ERC20 token has used its free trial of 100 drops. This is a constant 
     * function which does not alter the state of the contract and therefore does not require any gas 
     * or a signature to be executed. 
     * 
     * @param _addressOfToken The address of the token being queried.
     * 
     * @return hasFreeTrial true if the token being queried has not used its 100 first free trial drops, false
     * otherwise.
     * */
    function tokenHasFreeTrial(address _addressOfToken) public view returns(bool hasFreeTrial) {
        return tokenTrialDrops[_addressOfToken] < 100;
    }


    /**
     * Checks whether or not a user has a free trial. 
     * 
     * @param _addressOfUser The address of the user being queried.
     * 
     * @return hasFreeTrial true if the user address being queried has not used the first 100 free trial drops, false
     * otherwise.
     * */
    function userHasFreeTrial(address _addressOfUser) public view returns(bool hasFreeTrial) {
        return userTrialDrops[_addressOfUser] < 100;
    }
    
    /**
     * Checks how many remaining free trial drops a token has.
     * 
     * @param _addressOfToken the address of the token being queried.
     * 
     * @return remainingTrialDrops the total remaining free trial drops of a token.
     * */
    function getRemainingTokenTrialDrops(address _addressOfToken) public view returns(uint256 remainingTrialDrops) {
        if(tokenHasFreeTrial(_addressOfToken)) {
            uint256 maxTrialDrops =  100;
            return maxTrialDrops - tokenTrialDrops[_addressOfToken];
        } 
        return 0;
    }

    /**
     * Checks how many remaining free trial drops a user has.
     * 
     * @param _addressOfUser the address of the user being queried.
     * 
     * @return remainingTrialDrops the total remaining free trial drops of a user.
     * */
    function getRemainingUserTrialDrops(address _addressOfUser) public view returns(uint256 remainingTrialDrops) {
        if(userHasFreeTrial(_addressOfUser)) {
            uint256 maxTrialDrops =  100;
            return maxTrialDrops - userTrialDrops[_addressOfUser];
        }
        return 0;
    }
    
    /**
     * Allows for the price of drops to be changed by the owner of the contract. Any attempt made by 
     * any other account to invoke the function will result in a loss of gas and the price will remain 
     * untampered.
     * 
     * @return success true if function executes successfully, false otherwise.
     * */
    function setRate(uint256 _newRate) public onlyOwner returns(bool success) {
        require(
            _newRate != rate 
            && _newRate > 0
        );
        emit RateChanged(rate, _newRate);
        rate = _newRate;
        uint256 eth = 1 ether;
        dropUnitPrice = eth / rate;
        return true;
    }
    
    /**
     * Allows for the allowance of a token from its owner to this contract to be queried. 
     * 
     * As part of the ERC20 standard all tokens which fall under this category have an allowance 
     * function which enables owners of tokens to allow (or give permission) to another address 
     * to spend tokens on behalf of the owner. This contract uses this as part of its protocol.
     * Users must first give permission to the contract to transfer tokens on their behalf, however,
     * this does not mean that the tokens will ever be transferrable without the permission of the 
     * owner. This is a security feature which was implemented on this contract. It is not possible
     * for the owner of this contract or anyone else to transfer the tokens which belong to others. 
     * 
     * @param _addr The address of the token's owner.
     * @param _addressOfToken The contract address of the ERC20 token.
     * 
     * @return allowance The ERC20 token allowance from token owner to this contract. 
     * */
    function getTokenAllowance(address _addr, address _addressOfToken) public view returns(uint256 allowance) {
        ERC20Interface token = ERC20Interface(_addressOfToken);
        return token.allowance(_addr, address(this));
    }
    
    fallback() external payable {
        revert();
    }

    receive() external payable {
        revert();
    }
    
    /**
    * Checks if two strings are the same.
    *
    * @param _a String 1
    * @param _b String 2
    *
    * @return areEqual True if both strings are the same. False otherwise. 
    **/
    function stringsAreEqual(string memory _a, string memory _b) internal pure returns(bool areEqual) {
        bytes32 hashA = keccak256(abi.encodePacked(_a));
        bytes32 hashB = keccak256(abi.encodePacked(_b));
        return hashA == hashB;
    }
    
    /**
     * Allows for the distribution of Ether to be transferred to multiple recipients at 
     * a time. 
     * 
     * @param _recipients The list of addresses which will receive tokens. 
     * @param _values The corresponding amounts that the recipients will receive 
     * @param _afCode If the user is affiliated with a partner, they will provide this code so that 
     * the parter is paid commission.
     * 
     * @return success true if function executes successfully, false otherwise.
     * */
    function airdropNativeCurrency(address[] memory _recipients, uint256[] memory _values, uint256 _totalToSend, string memory _afCode) public payable returns(bool success) {
        require(_recipients.length == _values.length, "Total number of recipients and values are not equal");
        uint256 totalEthValue = _totalToSend;
        uint256 price = _recipients.length * dropUnitPrice;
        uint256 totalCost = totalEthValue + price;
        bool userHasTrial = userHasFreeTrial(msg.sender);
        bool isVIP = checkIsPremiumMember(msg.sender) == true;
        require(
            msg.value >= totalCost || isVIP || userHasTrial, 
            "Not enough funds sent with transaction!"
        );
        _afCode = processAffiliateCode(_afCode);
        if(!isVIP && !userHasTrial) {
            distributeCommission(price, _afCode);
        }
        if((isVIP || userHasTrial) && msg.value > _totalToSend) {
            payable(msg.sender).transfer((msg.value) - _totalToSend);
        } else {
            giveChange(totalCost);
        }
        for(uint i = 0; i < _recipients.length; i++) {
            payable(_recipients[i]).transfer(_values[i]);
        }
        if(userHasTrial) {
            userTrialDrops[msg.sender] = userTrialDrops[msg.sender] + _recipients.length;
        }
        emit EthAirdrop(msg.sender, _recipients.length, totalEthValue);
        return true;
    }

    /**
     * Allows for the distribution of an ERC20 token to be transferred to multiple recipients at 
     * a time. This function facilitates batch transfers of differing values (i.e., all recipients
     * can receive different amounts of tokens).
     * 
     * @param _addressOfToken The contract address of an ERC20 token.
     * @param _recipients The list of addresses which will receive tokens. 
     * @param _values The corresponding values of tokens which each address will receive.
     * @param _optimized Should only be enabled for tokens with gas optimized distribution functions. 
     * @param _afCode If the user is affiliated with a partner, they will provide this code so that 
     * the parter is paid commission.
     * 
     * @return success true if function executes successfully, false otherwise.
     * */    
    function erc20Airdrop(address _addressOfToken,  address[] memory _recipients, uint256[] memory _values, uint256 _totalToSend, bool _isDeflationary, bool _optimized, string memory _afCode) public payable returns(bool success) {
        string memory afCode = processAffiliateCode(_afCode);
        ERC20Interface token = ERC20Interface(_addressOfToken);
        require(_recipients.length == _values.length, "Total number of recipients and values are not equal");
        uint256 price = _recipients.length * dropUnitPrice;
        bool isPremiumOrListed = checkIsPremiumMember(msg.sender) || checkIsListedToken(_addressOfToken);
        bool eligibleForFreeTrial = tokenHasFreeTrial(_addressOfToken) && userHasFreeTrial(msg.sender);
        require(
            msg.value >= price || tokenHasFreeTrial(_addressOfToken) || userHasFreeTrial(msg.sender) || isPremiumOrListed,
            "Not enough funds sent with transaction!"
        );
        if((eligibleForFreeTrial || isPremiumOrListed) && msg.value > 0) {
            payable(msg.sender).transfer(msg.value);
        } else {
            giveChange(price);
        }

        if(_optimized) {
            token.transferFrom(msg.sender, address(this), _totalToSend);
            token.gasOptimizedAirdrop(_recipients,_values);
        } else {
            if(!_isDeflationary) {
                token.transferFrom(msg.sender, address(this), _totalToSend);
                for(uint i = 0; i < _recipients.length; i++) {
                    token.transfer(_recipients[i], _values[i]);
                }
                if(token.balanceOf(address(this)) > 0) {
                    token.transfer(msg.sender,token.balanceOf(address(this)));
                }
            } else {
                for(uint i=0; i < _recipients.length; i++) {
                    token.transferFrom(msg.sender, _recipients[i], _values[i]);
                }
            }
        }

        if(tokenHasFreeTrial(_addressOfToken)) {
            tokenTrialDrops[_addressOfToken] = tokenTrialDrops[_addressOfToken] + _recipients.length;
        }
        if(userHasFreeTrial(msg.sender)) {
            userTrialDrops[msg.sender] = userTrialDrops[msg.sender] + _recipients.length;
        }
        if(!eligibleForFreeTrial && !isPremiumOrListed) {
            distributeCommission(_recipients.length * dropUnitPrice, afCode);
        }
        emit TokenAirdrop(msg.sender, _addressOfToken, _recipients.length);
        return true;
    }


    /**
     * Allows for the distribution of ERC721 tokens to be transferred to multiple recipients at 
     * a time. 
     * 
     * @param _addressOfNFT The contract address of an ERC721 token collection.
     * @param _recipients The list of addresses which will receive tokens. 
     * @param _tokenIds The corresponding IDs of the NFT collection which each address will receive.
     * @param _optimized Should only be enabled for ERC721 token collections with gas optimized distribution functions. 
     * @param _afCode If the user is affiliated with a partner, they will provide this code so that 
     * the parter is paid commission.
     * 
     * @return success true if function executes successfully, false otherwise.
     * */ 
    function erc721Airdrop(address _addressOfNFT, address[] memory _recipients, uint256[] memory _tokenIds, bool _optimized, string memory _afCode) public payable returns(bool success) {
        require(_recipients.length == _tokenIds.length, "Total number of recipients and total number of NFT IDs are not the same");
        string memory afCode = processAffiliateCode(_afCode);
        ERC721Interface erc721 = ERC721Interface(_addressOfNFT);
        uint256 price = _recipients.length * dropUnitPrice;
        bool isPremiumOrListed = checkIsPremiumMember(msg.sender) || checkIsListedToken(_addressOfNFT);
        bool eligibleForFreeTrial = tokenHasFreeTrial(_addressOfNFT) && userHasFreeTrial(msg.sender);
        require(
            msg.value >= price || eligibleForFreeTrial || isPremiumOrListed,
            "Not enough funds sent with transaction!"
        );
        if((eligibleForFreeTrial || isPremiumOrListed) && msg.value > 0) {
            payable(msg.sender).transfer(msg.value);
        } else {
            giveChange(price);
        }
        if(_optimized){
            erc721.gasOptimizedAirdrop(msg.sender,_recipients,_tokenIds);
        } else {
            for(uint i = 0; i < _recipients.length; i++) {
                erc721.transferFrom(msg.sender, _recipients[i], _tokenIds[i]);
            }
        }
        if(tokenHasFreeTrial(_addressOfNFT)) {
            tokenTrialDrops[_addressOfNFT] = tokenTrialDrops[_addressOfNFT] + _recipients.length;
        }
        if(userHasFreeTrial(msg.sender)) {
            userTrialDrops[msg.sender] = userTrialDrops[msg.sender] + _recipients.length;
        }
        if(!eligibleForFreeTrial && !isPremiumOrListed) {
            distributeCommission(_recipients.length * dropUnitPrice, afCode);
        }
        emit NftAirdrop(msg.sender, _addressOfNFT, _recipients.length);
        return true;
    }

    /**
     * Allows for the distribution of ERC1155 tokens to be transferred to multiple recipients at 
     * a time. 
     * 
     * @param _addressOfNFT The contract address of an ERC1155 token contract.
     * @param _recipients The list of addresses which will receive tokens. 
     * @param _ids The corresponding IDs of the token collection which each address will receive.
     * @param _amounts The amount of tokens to send from each token type.
     * @param _optimized Should only be enabled for ERC721 token collections with gas optimized distribution functions. 
     * @param _afCode If the user is affiliated with a partner, they will provide this code so that 
     * the parter is paid commission.
     * 
     * @return success true if function executes successfully, false otherwise.
     * */ 
    function erc1155Airdrop(address _addressOfNFT, address[] memory _recipients, uint256[] memory _ids, uint256[] memory _amounts, bool _optimized, string memory _afCode) public payable returns(bool success) {
        require(_recipients.length == _ids.length, "Total number of recipients and total number of NFT IDs are not the same");
        require(_recipients.length == _amounts.length, "Total number of recipients and total number of amounts are not the same");
        string memory afCode = processAffiliateCode(_afCode);
        ERC1155Interface erc1155 = ERC1155Interface(_addressOfNFT);
        uint256 price = _recipients.length * dropUnitPrice;
        bool isPremiumOrListed = checkIsPremiumMember(msg.sender) || checkIsListedToken(_addressOfNFT);
        bool eligibleForFreeTrial = tokenHasFreeTrial(_addressOfNFT) && userHasFreeTrial(msg.sender);
        require(
            msg.value >= price || eligibleForFreeTrial || isPremiumOrListed,
            "Not enough funds sent with transaction!"
        );
        if((eligibleForFreeTrial || isPremiumOrListed) && msg.value > 0) {
            payable(msg.sender).transfer(msg.value);
        } else {
            giveChange(price);
        }
        if(_optimized){
            erc1155.gasOptimizedAirdrop(msg.sender,_recipients,_ids,_amounts);
        } else {
            for(uint i = 0; i < _recipients.length; i++) {
                erc1155.safeTransferFrom(msg.sender, _recipients[i], _ids[i], _amounts[i], "");
            }
        }
        if(tokenHasFreeTrial(_addressOfNFT)) {
            tokenTrialDrops[_addressOfNFT] = tokenTrialDrops[_addressOfNFT] + _recipients.length;
        }
        if(userHasFreeTrial(msg.sender)) {
            userTrialDrops[msg.sender] = userTrialDrops[msg.sender] + _recipients.length;
        }
        if(!eligibleForFreeTrial && !isPremiumOrListed) {
            distributeCommission(_recipients.length * dropUnitPrice, afCode);
        }
        emit NftAirdrop(msg.sender, _addressOfNFT, _recipients.length);
        return true;
    }


    /**
    * Send the owner and affiliates commissions.
    **/
    function distributeCommission(uint256 _profits, string memory _afCode) internal {
        if(!stringsAreEqual(_afCode,"void") && isAffiliate[affiliateCodeToAddr[_afCode]]) {
            uint256 commission = _profits * commissionPercentage[_afCode] / 100;
            payable(owner).transfer(_profits - commission);
            payable(affiliateCodeToAddr[_afCode]).transfer(commission);
            emit CommissionPaid(affiliateCodeToAddr[_afCode], commission);
        } else {
            payable(owner).transfer(_profits);
        }
    }


    /**
     * Allows the owner of the contract to withdraw any funds that may reside on the contract address.
     * */
    function withdrawFunds() public onlyOwner returns(bool success) {
        payable(owner).transfer(address(this).balance);
        return true;
    }

    /**
     * Allows for any ERC20 tokens which have been mistakenly  sent to this contract to be returned 
     * to the original sender by the owner of the contract. Any attempt made by any other account 
     * to invoke the function will result in a loss of gas and no tokens will be transferred out.
     * 
     * @param _addressOfToken The contract address of an ERC20 token.
     * @param _recipient The address which will receive tokens. 
     * @param _value The amount of tokens to refund.
     * 
     * @return success true if function executes successfully, false otherwise.
     * */  
    function withdrawERC20Tokens(address _addressOfToken,  address _recipient, uint256 _value) public onlyOwner returns(bool success){
        ERC20Interface token = ERC20Interface(_addressOfToken);
        token.transfer(_recipient, _value);
        emit ERC20TokensWithdrawn(_addressOfToken, _recipient, _value);
        return true;
    }

}