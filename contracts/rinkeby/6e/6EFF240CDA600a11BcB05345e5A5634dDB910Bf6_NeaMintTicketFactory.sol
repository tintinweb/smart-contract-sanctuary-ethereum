// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 *
 *                                    (/  #%%                                    
 *                                 ((((   %%%%%*                                 
 *                                /(/(,  #%%%%%%*                                
 *                          (((((/((/(   %%%%%%%%#%%%%/                          
 *                       ((((((((((((/  *%%%%%%%%%%%%%%%%#                       
 *                      /((((((((((((*  #%%%%%%%%%%%%%%%%%%%                     
 *                        ./(((((((((,  #%%%%%%%%%%%%%%%%%%%%%                   
 *                 *(((((((((((((((((   %%%%%%%%%%%%%%%%%%%%%%%                  
 *                ,((((((((((((((((((   %%%%%%%%%%%%%%%%%%%%%%%%                 
 *                (((((((((((((((((((   %%%%%%%%%%%%%%%%%%%%%%%%%                
 *               .(/(((((((((((((((((   %%%%%%%%%%%%%%%%%%%%%%%%#.               
 *                    (((((((((((((((   %%%%%%%%%%%%%%%%%%%%%%%%%                
 *                   /(((((((((((((((   %%%%%%%%%%%%%%%%%%%%%##*                 
 *               *(((((((((((((((((((   %%%%%#%%#%%%%%%%%%%#%%                   
 *                (((((((((((((((((((.  %%%%%          %%%%%%                    
 *                (((((((((((((((((((,  #%%%         .%%%%%%,                    
 *                 ((((((((((((((((((/  (%%%       %%%%%%%%%.                    
 *                           ((((((((/  ,%%%   .%%%%%%%%%%%%%                    
 *                        *((((((((((/   %%#   %%%%%%%%%%%%%%                    
 *                    //((((((((((((((        ,%%%%%%%%%%%%%.                    
 *                      ((((((((((((((        %%%%%%%%%%%%(                      
 *                        (//(((((((((       *%%%%%%%%%#%                        
 *                          /(((((((((,      %%%%%%#%%(                          
 *                             (((((((*     *%%%%%%%                             
 *                               ./((((     %%%%#  
 * 
 * Hello Guardians,
 * We don't have a lot of time. You have been called upon to act, the time is now or never.
 * Together we can collectively push back the damage that has been done to the amazon.
 * 
 * This contract emits tickets that entitle you to NFTs  which you can use to join the fight.
 * Gas saving measures have been used to even further reduce carbon emission.
 * ~ See you in the rainforest.
 *
 * Project By: @nemus_earth
 * Developed By: @notmokk
 * 
 */

import "./ReentrancyGuard.sol";
import "./AccessControl.sol";
import "./ERC1155.sol";
import "./Strings.sol";
import "./Counters.sol";
import './AbstractMintVoucherFactory.sol';

contract NeaMintTicketFactory is AbstractMintVoucherFactory, ReentrancyGuard  {
    using Counters for Counters.Counter;

    Counters.Counter private mtCounter; 
    
    uint256 private constant MAX_PER_EARLY_ACCESS_ADDRESS = 3;

    address payable public treasuryWallet;
    address payable public nemusWallet;
    uint256 public treasuryPercentage;
    uint256 public nemusPercentage;

    mapping(address => bool) public isOnEarlyAccessList;
    mapping(address => uint256) public earlyAccessMintedCounts;
    mapping(uint256 => MintTicket) public mintTickets;
    
    event Claimed(uint index, address indexed account, uint amount);
    event ClaimedMultiple(uint[] index, address indexed account, uint[] amount);

    struct MintTicketParam {
        uint256 mtIndex; // Ticket index referencing mapping
        bool saleIsOpen; // Sale open or close boolean
        uint256 earlyAccessOpens; // Early access starting timestamp
        uint256 publicSaleOpens; // Public sale starting timestamp
        uint256 publicSaleCloses; // Public sale ending timestamp
        uint256 mintPrice; // Price of minting
        uint256 maxSupply; // Max possible supply of individual tickets
        uint256 maxPerWallet; // Max amount per users wallet
        uint256 maxMintPerTxn; // Max amount a user can mint per tx
        uint256 sizeID; // ID for ticket size reference
        string metadataHash; // ID for metadata reference
        address redeemableContract; // contract of the redeemable NFT
    }

    struct MintTicket {
        bool saleIsOpen;
        uint256 earlyAccessOpens; // Early access starting timestamp
        uint256 publicSaleOpens; // Public sale starting timestamp
        uint256 publicSaleCloses; // Public sale ending timestamp
        uint256 mintPrice; // Price of minting
        uint256 maxSupply; // Max possible supply of individual tickets
        uint256 maxPerWallet; // Max amount per users wallet
        uint256 maxMintPerTxn; // Max amount a user can mint per tx
        uint256 sizeID; // ID for ticket size reference
        string metadataHash; // ID for metadata reference
        address redeemableContract; // contract of the redeemable NFT
        mapping(address => uint256) claimedMTs;
    }
   
    constructor(
        string memory _name, 
        string memory _symbol,
        address _treasuryAddress,
        address _nemusAddress
    ) ERC1155("https://nemus-media.nyc3.digitaloceanspaces.com/tickets/seruini/genesis/metadata/") {
        require(address(_treasuryAddress) != address(0) && address(_nemusAddress) != address(0), "Treasury address cannot be zero");

        name_ = _name;
        symbol_ = _symbol;
        treasuryWallet = payable(_treasuryAddress);
        nemusWallet = payable(_nemusAddress);
        treasuryPercentage = 30;
        nemusPercentage = 70;
    }

    function addMintTicket(
        uint256 _earlyAccessOpens,
        uint256 _publicSaleOpens, 
        uint256 _publicSaleCloses, 
        uint256 _mintPrice, 
        uint256 _maxSupply,
        uint256 _maxMintPerTxn,
        uint256 _sizeID,
        string memory _metadataHash,
        address _redeemableContract,
        uint256 _maxPerWallet
    ) external onlyOwner {
        require(_earlyAccessOpens < _publicSaleOpens, "addMintTicket: open window must be before close window");
        require(_publicSaleOpens < _publicSaleCloses, "addMintTicket: open window must be before close window");
        require(_publicSaleOpens > 0 && _publicSaleCloses > 0 && _earlyAccessOpens > 0, "addMintTicket: window cannot be 0");
        require(_publicSaleOpens > block.timestamp && _earlyAccessOpens > block.timestamp, "addMintTicket: open window cannot be in the past");
        require(address(_redeemableContract) != address(0), "addMintTicket: cannot be zero address");


        MintTicket storage mt = mintTickets[mtCounter.current()];
        mt.saleIsOpen = false;
        mt.earlyAccessOpens = _earlyAccessOpens;
        mt.publicSaleOpens = _publicSaleOpens;
        mt.publicSaleCloses = _publicSaleCloses;
        mt.mintPrice = _mintPrice;
        mt.maxSupply = _maxSupply;
        mt.maxMintPerTxn = _maxMintPerTxn;
        mt.maxPerWallet = _maxPerWallet;
        mt.sizeID = _sizeID;
        mt.metadataHash = _metadataHash;
        mt.redeemableContract = _redeemableContract;
        mtCounter.increment();

    }

    function editMintTicket(
        MintTicketParam calldata params
    ) external onlyOwner {             
        require(mintTicketExists(params.mtIndex), "Mint ticket does not exist");

        require(params.earlyAccessOpens < params.publicSaleOpens, "editMintTicket: open window must be before close window");
        require(params.publicSaleOpens < params.publicSaleCloses, "editMintTicket: open window must be before close window");
        require(params.publicSaleOpens > 0 && params.publicSaleCloses > 0 && params.earlyAccessOpens > 0, "editMintTicket: window cannot be 0");
        require(address(params.redeemableContract) != address(0), "addMintTicket: cannot be zero address");

        mintTickets[params.mtIndex].earlyAccessOpens = params.earlyAccessOpens;
        mintTickets[params.mtIndex].publicSaleOpens = params.publicSaleOpens;
        mintTickets[params.mtIndex].publicSaleCloses = params.publicSaleCloses;
        mintTickets[params.mtIndex].mintPrice = params.mintPrice;  
        mintTickets[params.mtIndex].maxSupply = params.maxSupply;    
        mintTickets[params.mtIndex].maxMintPerTxn = params.maxMintPerTxn;
        mintTickets[params.mtIndex].sizeID = params.sizeID; 
        mintTickets[params.mtIndex].metadataHash = params.metadataHash;    
        mintTickets[params.mtIndex].redeemableContract = params.redeemableContract;
        mintTickets[params.mtIndex].saleIsOpen = params.saleIsOpen; 
        mintTickets[params.mtIndex].maxPerWallet = params.maxPerWallet; 
    }      

    function setMintTicketEarlyAccessOpens(uint256 _index, uint256 _earlyAccess) public onlyOwner {
        require(mintTicketExists(_index), "Mint ticket does not exist");
        require((_earlyAccess < mintTickets[_index].publicSaleOpens) && (_earlyAccess > 0), "Cannot be after public opening");
        mintTickets[_index].earlyAccessOpens = _earlyAccess;
    }

    function setMintTicketPublicSaleOpens(uint256 _index, uint256 _publicSaleOpens) public onlyOwner {
        require(mintTicketExists(_index), "Mint ticket does not exist");
        require((_publicSaleOpens < mintTickets[_index].publicSaleCloses) && (_publicSaleOpens > 0), "Cannot be after public closing");
        mintTickets[_index].publicSaleOpens = _publicSaleOpens;
    }

    function setMintTicketPublicSaleCloses(uint256 _index, uint256 _publicSaleCloses) public onlyOwner {
        require(mintTicketExists(_index), "Mint ticket does not exist");
        require((_publicSaleCloses > mintTickets[_index].publicSaleOpens) && (_publicSaleCloses > 0), "Cannot be after public closing");
        mintTickets[_index].publicSaleCloses = _publicSaleCloses;
    }

    function setMintTicketPrice(uint256 _index, uint256 _mintPrice) public onlyOwner {
        require(mintTicketExists(_index), "Mint ticket does not exist");
        mintTickets[_index].mintPrice = _mintPrice;
    } 

    function setMintTicketMaxSupplyt(uint256 _index, uint256 _maxSupply) public onlyOwner {
        require(mintTicketExists(_index), "Mint ticket does not exist");
        mintTickets[_index].maxSupply = _maxSupply;
    } 

    function setMintTicketMaxMint(uint256 _index, uint256 _maxMintPerTxn) public onlyOwner {
        require(mintTicketExists(_index), "Mint ticket does not exist");
        mintTickets[_index].maxMintPerTxn = _maxMintPerTxn;
    }

    function setMintTicketMaxPerWallet(uint256 _index, uint256 _maxMintPerWallet) public onlyOwner {
        require(mintTicketExists(_index), "Mint ticket does not exist");
        mintTickets[_index].maxPerWallet = _maxMintPerWallet;
    }

    function setMintTicketSizeId(uint256 _index, uint256 _sizeId) public onlyOwner {
        require(mintTicketExists(_index), "Mint ticket does not exist");
        mintTickets[_index].sizeID = _sizeId;
    }

    function setMintTicketMetadataId(uint256 _index, string calldata _metadataId) public onlyOwner {
        require(mintTicketExists(_index), "Mint ticket does not exist");
        mintTickets[_index].metadataHash = _metadataId;
    }

    function setMintTicketRedeemableContract(uint256 _index, address _redeemableContract) public onlyOwner {
        require(mintTicketExists(_index), "Mint ticket does not exist");
        require(address(_redeemableContract) != address(0), "Cannot be zero address");
        mintTickets[_index].redeemableContract = _redeemableContract;
    }

    function mintTicketExists(uint256 _index) public view returns (bool) {
        require(mintTickets[_index].publicSaleOpens > 0, "Mint Ticket does not exist");
        return true;
    }

    function turnSaleOn(uint256 _index) external onlyOwner{
        require(mintTicketExists(_index), "Mint ticket does not exist");
         mintTickets[_index].saleIsOpen = true;
    }

    function turnSaleOff(uint256 _index) external onlyOwner{
        require(mintTicketExists(_index), "Mint ticket does not exist");
         mintTickets[_index].saleIsOpen = false;
    }


    function burnFromRedeem(
        address account, 
        uint256 mtIndex, 
        uint256 amount
    ) external {
        require(mintTickets[mtIndex].redeemableContract == msg.sender, "Burnable: Only allowed from redeemable contract");
        _burn(account, mtIndex, amount);
    }  

    function claim(
        uint256 amount,
        uint256 mtIndex
    ) external payable nonReentrant {
        // Verify claim is valid
        require(isValidClaim(amount,mtIndex));
        // Return excess funds to sender if they've overpaid
        uint256 excessPayment = msg.value - (amount * mintTickets[mtIndex].mintPrice);
        if (excessPayment > 0) {
            (bool returnExcessStatus, ) = _msgSender().call{value: excessPayment}("");
            require(returnExcessStatus, "Error returning excess payment");
        }
        // Add claimed amount to mintTicket index to keep track of user claiming
        mintTickets[mtIndex].claimedMTs[msg.sender] = mintTickets[mtIndex].claimedMTs[msg.sender] + amount;
        _mint(msg.sender, mtIndex, amount, "");
        // Emit claimed event
        emit Claimed(mtIndex, msg.sender, amount);
    }

    function claimMultiple(
        uint256[] calldata amounts,
        uint256[] calldata mtIndexes
    ) external payable nonReentrant {

        uint256 excessPayment = msg.value;
        uint256 totalTicketCost = 0;
        //validate all tokens being claimed and aggregate a total cost due
        for (uint i=0; i< mtIndexes.length; i++) {
            require(validateNonDupliateIndex(mtIndexes, mtIndexes[i]), "Index is duplcate");
            require(isValidClaim(amounts[i],mtIndexes[i]), "One or more claims are invalid");
            uint256 totalAmount = amounts[i] * mintTickets[mtIndexes[i]].mintPrice;
            totalTicketCost += totalAmount;
            excessPayment -= totalAmount ;
            mintTickets[mtIndexes[i]].claimedMTs[msg.sender] = mintTickets[mtIndexes[i]].claimedMTs[msg.sender] + amounts[i];
        }

        require(msg.value >= totalTicketCost, "Not enough ETH sent");

        if (excessPayment > 0) {
            (bool returnExcessStatus, ) = _msgSender().call{value: excessPayment}("");
            require(returnExcessStatus, "Error returning excess payment");
        }
    
        _mintBatch(msg.sender, mtIndexes, amounts, "");
        // Emit claimed event
        emit ClaimedMultiple(mtIndexes, msg.sender, amounts);

    }

    function claimEarlyAccess(uint256 _count, uint256 mtIndex) external payable nonReentrant {
        require(isValidEarlyAccessClaim(_count, mtIndex));

        // Return excess funds to sender if they've overpaid
        uint256 excessPayment = msg.value - (_count * mintTickets[mtIndex].mintPrice);
        if (excessPayment > 0) {
            (bool returnExcessStatus, ) = _msgSender().call{value: excessPayment}("");
            require(returnExcessStatus, "Error returning excess payment");
        }

        // Add claimed amount to mintTicket index to keep track of user claiming
        mintTickets[mtIndex].claimedMTs[msg.sender] = mintTickets[mtIndex].claimedMTs[msg.sender] + _count;
        uint256 userMintedAmount = earlyAccessMintedCounts[msg.sender] + _count;
        require(userMintedAmount <= MAX_PER_EARLY_ACCESS_ADDRESS, "Max early access count per address exceeded");

        // Mint it!
        _mint(msg.sender, mtIndex, _count, "");

        // Add early access count to keep track of early access claim
        earlyAccessMintedCounts[msg.sender] = userMintedAmount;

        // Emit claimed event
        emit Claimed(mtIndex, msg.sender, _count);
    }

    function claimMultipleEarlyAccess(uint256[] calldata _count, uint256[] calldata mtIndexes) external payable nonReentrant {
        //validate all tokens being claimed and aggregate a total cost due
        // Add claimed amount to mintTicket index to keep track of user claiming
        uint256 excessPayment = msg.value;
        uint256 userMintedAmount = earlyAccessMintedCounts[msg.sender];
        uint256 totalTicketCost = 0;
        for (uint i=0; i< mtIndexes.length; i++) {
            require(validateNonDupliateIndex(mtIndexes, mtIndexes[i]), "Index is duplicated");
            require(isValidEarlyAccessClaim(_count[i], mtIndexes[i]), "One or more claims are invalid");
            mintTickets[mtIndexes[i]].claimedMTs[msg.sender] = mintTickets[mtIndexes[i]].claimedMTs[msg.sender] + _count[i];
            uint256 totalAmount = _count[i] * mintTickets[mtIndexes[i]].mintPrice;
            userMintedAmount += _count[i];
            totalTicketCost += totalAmount;
            excessPayment -= totalAmount;
            if (msg.sender != nemusWallet) {
                require(userMintedAmount <= MAX_PER_EARLY_ACCESS_ADDRESS, "Max early access count per address exceeded");
            }
        }

        require(msg.value >= totalTicketCost, "Not enough ETH sent");

        if (excessPayment > 0) {
            (bool returnExcessStatus, ) = _msgSender().call{value: excessPayment}("");
            require(returnExcessStatus, "Error returning excess payment");
        }

        // Mint it!
        _mintBatch(msg.sender, mtIndexes, _count, "");

        // Add early access count to keep track of early access claim
        earlyAccessMintedCounts[msg.sender] = userMintedAmount;

        // Emit claimed event
        emit ClaimedMultiple(mtIndexes, msg.sender, _count);

    }

    function mint(
        address to,
        uint256 numPasses,
        uint256 mtIndex) public onlyOwner
    {
        _mint(to, mtIndex, numPasses, "");
    }

    function mintBatch(
        address to,
        uint256[] calldata numPasses,
        uint256[] calldata mtIndexes) public onlyOwner
    {
        _mintBatch(to, mtIndexes, numPasses, "");
    }

    function isValidClaim(
        uint256 numPasses,
        uint256 mtIndexes) internal view returns (bool) {
         // verify contract is not paused
        require(mintTickets[mtIndexes].saleIsOpen, "Sale is paused");
        require(!paused(), "Claim: claiming is paused");
        // Verify within window
        require (block.timestamp > mintTickets[mtIndexes].publicSaleOpens && block.timestamp < mintTickets[mtIndexes].publicSaleCloses, "Claim: time window closed");
        // Verify minting price
        require(msg.value >= (numPasses * mintTickets[mtIndexes].mintPrice), "Claim: Ether value incorrect");
        // Verify numPasses is within remaining claimable amount 
        require((mintTickets[mtIndexes].claimedMTs[msg.sender] + numPasses <= mintTickets[mtIndexes].maxPerWallet), "Claim: Not allowed to claim that many from one wallet");
        require(numPasses <= mintTickets[mtIndexes].maxMintPerTxn, "Max quantity per transaction exceeded");

        require(totalSupply(mtIndexes) + numPasses <= mintTickets[mtIndexes].maxSupply, "Purchase would exceed max supply");
        
        return true;
         
    }

    function isValidEarlyAccessClaim(uint256 _count, uint256 mtIndex) internal view returns (bool) {
            require(mintTickets[mtIndex].saleIsOpen, "Sale is paused");
            require(!paused(), "Claim: claiming is paused");
            // Verify there is an amount to be minted
            require(_count != 0, "Invalid count");
            // Verfiy sender is on early access list
            require(isOnEarlyAccessList[msg.sender], "Address not on early access list");
            // Verify within window between early access opens and public sale opens.
            require(isEarlyAccessOpen(mtIndex), "Early access window not open");
            // Verify sender value is correct for amount of passes being minted
            require(msg.value >= (_count * mintTickets[mtIndex].mintPrice), "Claim: Ether value incorrect");
            // Verify purchaase amount does not exceed max amount of passes
            require(totalSupply(mtIndex) + _count <= mintTickets[mtIndex].maxSupply, "Purchase would exceed max supply");

            return true;
    }

    function getClaimedMts(uint256 mtIndex, address userAdress) public view returns (uint256) {
        return mintTickets[mtIndex].claimedMTs[userAdress];
    }

    function getTicketSizeID(uint256 mtIndex) external view returns(uint256) {
        return mintTickets[mtIndex].sizeID;
    }

    function getRemainingEarlyAccessMints(address _addr) public view returns (uint256) {
        if (!isOnEarlyAccessList[_addr]) {
            return 0;
        }
        return MAX_PER_EARLY_ACCESS_ADDRESS - earlyAccessMintedCounts[_addr];
    }

    function addToEarlyAccessList(address[] memory toEarlyAccessList) external onlyOwner {
        for (uint256 i = 0; i < toEarlyAccessList.length; i++) {
            isOnEarlyAccessList[toEarlyAccessList[i]] = true;
        }
    }

    function removeFromEarlyAccessList(address[] memory toRemove) external onlyOwner {
        for (uint256 i = 0; i < toRemove.length; i++) {
            isOnEarlyAccessList[toRemove[i]] = false;
        }
    }

    function isEarlyAccessOpen(uint256 mtIndex) public view returns (bool) {
        return (block.timestamp >= mintTickets[mtIndex].earlyAccessOpens && block.timestamp <= mintTickets[mtIndex].publicSaleOpens);
    }

    function isSaleOpen(uint256 mtIndex) public view returns (bool) {
        return mintTickets[mtIndex].saleIsOpen;
    }

    function validateNonDupliateIndex(uint256[] calldata _indexes, uint256 _search) public pure returns (bool) {
        uint256 matchCount = 0;
        for (uint i=0; i< _indexes.length; i++) {
            if(_indexes[i] == _search) {
                matchCount++;
                if ( matchCount > 1) {
                    return false;
                }
            }
        }
        return true;
    }   

    function updatePayoutPercentage(uint256 _treasuryPercentage, uint256 _nemusPercentage) external onlyOwner 
    {
        require(_treasuryPercentage + _nemusPercentage <= 100, "Total percentage cannot be greater than 100");
        treasuryPercentage = _treasuryPercentage;
        nemusPercentage = _nemusPercentage;
    }
    
    function withdrawFunds() public onlyOwner
    {
        uint256 currentBalance = address(this).balance;
        uint256 amount1 = (currentBalance * treasuryPercentage)/100;
        uint256 amount2 = currentBalance - amount1;

        (bool success1, ) = address(treasuryWallet).call{value:amount1}("");
        require(success1, "Transfer1 failed.");

        (bool success2, ) = address(nemusWallet).call{value:amount2}("");
        require(success2, "Transfer2 failed.");
    }

    function uri(uint256 _id) public view override returns (string memory) {
            require(totalSupply(_id) > 0, "URI: nonexistent token");
            return string(abi.encodePacked(super.uri(_id), mintTickets[_id].metadataHash));
    } 
}