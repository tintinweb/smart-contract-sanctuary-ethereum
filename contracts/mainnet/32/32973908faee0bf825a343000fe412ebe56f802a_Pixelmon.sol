pragma solidity ^0.8.10;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Strings.sol";

/// @notice Thrown when completing the transaction results in overallocation of Pixelmon.
error MintedOut();
/// @notice Thrown when the dutch auction phase has not yet started, or has already ended.
error AuctionNotStarted();
/// @notice Thrown when the user has already minted two Pixelmon in the dutch auction.
error MintingTooMany();
/// @notice Thrown when the value of the transaction is not enough for the current dutch auction or mintlist price.
error ValueTooLow();
/// @notice Thrown when the user is not on the mintlist.
error NotMintlisted();
/// @notice Thrown when the caller is not the EvolutionSerum contract, and is trying to evolve a Pixelmon.
error UnauthorizedEvolution();
/// @notice Thrown when an invalid evolution is given by the EvolutionSerum contract.
error UnknownEvolution();


//  ______   __     __  __     ______     __         __    __     ______     __   __    
// /\  == \ /\ \   /\_\_\_\   /\  ___\   /\ \       /\ "-./  \   /\  __ \   /\ "-.\ \   
// \ \  _-/ \ \ \  \/_/\_\/_  \ \  __\   \ \ \____  \ \ \-./\ \  \ \ \/\ \  \ \ \-.  \  
//  \ \_\    \ \_\   /\_\/\_\  \ \_____\  \ \_____\  \ \_\ \ \_\  \ \_____\  \ \_\\"\_\ 
//   \/_/     \/_/   \/_/\/_/   \/_____/   \/_____/   \/_/  \/_/   \/_____/   \/_/ \/_/ 
//
/// @title Generation 1 Pixelmon NFTs
/// @author delta devs (https://www.twitter.com/deltadevelopers)
contract Pixelmon is ERC721, Ownable {
    using Strings for uint256;

    /*///////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @dev Determines the order of the species for each tokenId, mechanism for choosing starting index explained post mint, explanation hash: acb427e920bde46de95103f14b8e57798a603abcf87ff9d4163e5f61c6a56881.
    uint constant public provenanceHash = 0x9912e067bd3802c3b007ce40b6c125160d2ccb5352d199e20c092fdc17af8057;

    /// @dev Sole receiver of collected contract funds, and receiver of 330 Pixelmon in the constructor.
    address constant gnosisSafeAddress = 0xF6BD9Fc094F7aB74a846E5d82a822540EE6c6971;

    /// @dev 7750, plus 330 for the Pixelmon Gnosis Safe
    uint constant auctionSupply = 7750 + 330;

    /// @dev The offsets are the tokenIds that the corresponding evolution stage will begin minting at.
    uint constant secondEvolutionOffset = 10005;
    uint constant thirdEvolutionOffset = secondEvolutionOffset + 4013;
    uint constant fourthEvolutionOffset = thirdEvolutionOffset + 1206;

    /*///////////////////////////////////////////////////////////////
                        EVOLUTIONARY STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @dev The next tokenID to be minted for each of the evolution stages
    uint secondEvolutionSupply = 0;
    uint thirdEvolutionSupply = 0;
    uint fourthEvolutionSupply = 0;

    /// @notice The address of the contract permitted to mint evolved Pixelmon.
    address public serumContract;

    /// @notice Returns true if the user is on the mintlist, if they have not already minted.
    mapping(address => bool) public mintlisted;

    /*///////////////////////////////////////////////////////////////
                            AUCTION STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice Starting price of the auction.
    uint256 constant public auctionStartPrice = 3 ether;

    /// @notice Unix Timestamp of the start of the auction.
    /// @dev Monday, February 7th 2022, 13:00:00 converted to 1644256800 (GMT -5)
    uint256 constant public auctionStartTime = 1644256800;

    /// @notice Current mintlist price, which will be updated after the end of the auction phase.
    /// @dev We started with signatures, then merkle tree, but landed on mapping to reduce USER gas fees.
    uint256 public mintlistPrice = 0.75 ether;

    /*///////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public baseURI;

    /*///////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Deploys the contract, minting 330 Pixelmon to the Gnosis Safe and setting the initial metadata URI.
    constructor(string memory _baseURI) ERC721("Pixelmon", "PXLMN") {
        baseURI = _baseURI;
        unchecked {
            balanceOf[gnosisSafeAddress] += 330;
            totalSupply += 330;
            for (uint256 i = 0; i < 330; i++) {
                ownerOf[i] = gnosisSafeAddress;
                emit Transfer(address(0), gnosisSafeAddress, i);
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                            METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Allows the contract deployer to set the metadata URI.
    /// @param _baseURI The new metadata URI.
    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        return string(abi.encodePacked(baseURI, id.toString()));
    }

    /*///////////////////////////////////////////////////////////////
                        DUTCH AUCTION LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Calculates the auction price with the accumulated rate deduction since the auction's begin
    /// @return The auction price at the current time, or 0 if the deductions are greater than the auction's start price.
    function validCalculatedTokenPrice() private view returns (uint) {
        uint priceReduction = ((block.timestamp - auctionStartTime) / 10 minutes) * 0.1 ether;
        return auctionStartPrice >= priceReduction ? (auctionStartPrice - priceReduction) : 0;
    }

    /// @notice Calculates the current dutch auction price, given accumulated rate deductions and a minimum price.
    /// @return The current dutch auction price
    function getCurrentTokenPrice() public view returns (uint256) {
        return max(validCalculatedTokenPrice(), 0.2 ether);
    }

    /// @notice Purchases a Pixelmon NFT in the dutch auction
    /// @param mintingTwo True if the user is minting two Pixelmon, otherwise false.
    /// @dev balanceOf is fine, team is aware and accepts that transferring out and repurchasing can be done, even by contracts. 
    function auction(bool mintingTwo) public payable {
        if(block.timestamp < auctionStartTime || block.timestamp > auctionStartTime + 1 days) revert AuctionNotStarted();

        uint count = mintingTwo ? 2 : 1;
        uint price = getCurrentTokenPrice();

        if(totalSupply + count > auctionSupply) revert MintedOut();
        if(balanceOf[msg.sender] + count > 2) revert MintingTooMany();
        if(msg.value < price * count) revert ValueTooLow();

        mintingTwo ? _mintTwo(msg.sender) : _mint(msg.sender, totalSupply);
    }
    
    /// @notice Mints two Pixelmons to an address
    /// @param to Receiver of the two newly minted NFTs
    /// @dev errors taken from super._mint
    function _mintTwo(address to) internal {
        require(to != address(0), "INVALID_RECIPIENT");
        require(ownerOf[totalSupply] == address(0), "ALREADY_MINTED");
        uint currentId = totalSupply;

        /// @dev unchecked because no arithmetic can overflow
        unchecked {
            totalSupply += 2;
            balanceOf[to] += 2;
            ownerOf[currentId] = to;
            ownerOf[currentId + 1] = to;
            emit Transfer(address(0), to, currentId);
            emit Transfer(address(0), to, currentId + 1);
        }
    }


    /*///////////////////////////////////////////////////////////////
                        MINTLIST MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Allows the contract deployer to set the price of the mintlist. To be called before uploading the mintlist.
    /// @param price The price in wei of a Pixelmon NFT to be purchased from the mintlist supply.
    function setMintlistPrice(uint256 price) public onlyOwner {
        mintlistPrice = price;
    }

    /// @notice Allows the contract deployer to add a single address to the mintlist.
    /// @param user Address to be added to the mintlist.
    function mintlistUser(address user) public onlyOwner {
        mintlisted[user] = true;
    }

    /// @notice Allows the contract deployer to add a list of addresses to the mintlist.
    /// @param users Addresses to be added to the mintlist.
    function mintlistUsers(address[] calldata users) public onlyOwner {
        for (uint256 i = 0; i < users.length; i++) {
           mintlisted[users[i]] = true; 
        }
    }

    /// @notice Purchases a Pixelmon NFT from the mintlist supply
    /// @dev We do not check if auction is over because the mintlist will be uploaded after the auction. 
    function mintlistMint() public payable {
        if(totalSupply >= secondEvolutionOffset) revert MintedOut();
        if(!mintlisted[msg.sender]) revert NotMintlisted();
        if(msg.value < mintlistPrice) revert ValueTooLow();

        mintlisted[msg.sender] = false;
        _mint(msg.sender, totalSupply);
    }

    /// @notice Withdraws collected funds to the Gnosis Safe address
    function withdraw() public onlyOwner {
        (bool success, ) = gnosisSafeAddress.call{value: address(this).balance}("");
        require(success);
    }

    /*///////////////////////////////////////////////////////////////
                            ROLL OVER LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Allows the contract deployer to airdrop Pixelmon to a list of addresses, in case the auction doesn't mint out
    /// @param addresses Array of addresses to receive Pixelmon
    function rollOverPixelmons(address[] calldata addresses) public onlyOwner {
        if(totalSupply + addresses.length > secondEvolutionOffset) revert MintedOut();

        for (uint256 i = 0; i < addresses.length; i++) {
            _mint(msg.sender, totalSupply);
        }
    }

    /*///////////////////////////////////////////////////////////////
                        EVOLUTIONARY LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Sets the address of the contract permitted to call mintEvolvedPixelmon
    /// @param _serumContract The address of the EvolutionSerum contract
    function setSerumContract(address _serumContract) public onlyOwner {
        serumContract = _serumContract; 
    }

    /// @notice Mints an evolved Pixelmon
    /// @param receiver Receiver of the evolved Pixelmon
    /// @param evolutionStage The evolution (2-4) that the Pixelmon is undergoing
    function mintEvolvedPixelmon(address receiver, uint evolutionStage) public payable {
        if(msg.sender != serumContract) revert UnauthorizedEvolution();

        if (evolutionStage == 2) {
            if(secondEvolutionSupply >= 4013) revert MintedOut();
            _mint(receiver, secondEvolutionOffset + secondEvolutionSupply);
            unchecked {
                secondEvolutionSupply++;
            }
        } else if (evolutionStage == 3) {
            if(thirdEvolutionSupply >= 1206) revert MintedOut();
            _mint(receiver, thirdEvolutionOffset + thirdEvolutionSupply);
            unchecked {
                thirdEvolutionSupply++;
            }
        } else if (evolutionStage == 4) {
            if(fourthEvolutionSupply >= 33) revert MintedOut();
            _mint(receiver, fourthEvolutionOffset + fourthEvolutionSupply);
            unchecked {
                fourthEvolutionSupply++;
            }
        } else  {
            revert UnknownEvolution();
        }
    }


    /*///////////////////////////////////////////////////////////////
                                UTILS
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns the greater of two numbers.
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

}