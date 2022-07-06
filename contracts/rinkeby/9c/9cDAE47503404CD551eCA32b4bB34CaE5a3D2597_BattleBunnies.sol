// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./Percentages.sol";
contract BattleBunnies is ERC721A, Ownable, ReentrancyGuard, Percentages {
    // Max supply 
    uint256 public maxSupply;
    IERC721 public TBB_GENESIS;

    // Merkle Root
    bytes32 public alRoot;

    uint256 public price;
    uint256 public alPrice;
    uint256 public holderPrice;

    uint256 maxPerTx = 100;

    // 0 - closed
    // 1 - holder only
    // 2 - allow list only
    // 3 - allow list and public
    uint256 public state;
    
    mapping(address => bool) private isAdmin;

    event minted(address minter, uint256 price, address recipient, uint256 amount);
    event stateChanged(uint256 _state);


    modifier onlyAdmin {
        require(isAdmin[_msgSender()] == true, "onlyAdmin: Sender must be admin");
        _;
    }

    struct Wallets {
        uint256 percentage;
        address wallet;
    }
    Wallets[] public wallets;

    constructor(
        string memory name,     // The Battle Bunnies
        string memory symbol,   // TBB
        uint256 _maxSupply,     // 5001
        uint256 _price,         // 110000000000000000 WEI
        uint256 _alPrice,       // 100000000000000000 WEI
        uint256 _holderPrice    // 77700000000000000 WEI

    ) 
    ERC721A(name, symbol, 100, _maxSupply) 
    {
        maxSupply = _maxSupply;
        price = _price;
        alPrice = _alPrice;
        holderPrice = _holderPrice;
        TBB_GENESIS = IERC721(0xF8e9776840639b0fFEa1EcB31fADF974Cf48A435);
        _safeMint(0x0000000000000000000000000000000000000000, 1);

        URI = "https://us-central1-battle-bunnies-mint.cloudfunctions.net/get-metadata?tokenid=";
        isAdmin[_msgSender()] = true;
        wallets.push(Wallets(35, 0x644580B17fd98F42B37B56773e71dcfD81eff4cB));
        wallets.push(Wallets(25, 0x1954e9bE7E604Ff1A0f6D20dabC54F4DD86d8e46));
        wallets.push(Wallets(15, 0x8245508E4eeE2Ec32200DeeCD7E85A3050Af7C49));
        wallets.push(Wallets(10, 0x0fDA31E3454F429701082A20380D9CfAaDfefb54));
        wallets.push(Wallets(8, 0xd8d3e705C6302bA3c30e4F718920074e2F575102));
        wallets.push(Wallets(5, 0x53DE2a775476E35120bc070ff9667044e6732A7f));
        wallets.push(Wallets(2, 0x67CE09d244D8CD9Ac49878B76f5955AB4aC0A478));
    }

    function isAllowListed(address _recipient, bytes32[] calldata _merkleProof) public view returns(bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_recipient));
        bool isal = MerkleProof.verify(_merkleProof, alRoot, leaf);
        return isal;
    }

    // allow AL and public mint to happen simultaneously
    // add holders to merkle root
    function mint(uint256 amount, bytes32[] calldata _merkleProof) external payable nonReentrant {
        require(state > 0, "Sale is closed");
        require(totalSupply() + amount <= maxSupply, "exceeds max supply");
        require(amount <= maxPerTx, "exceeds max per tx");

        uint256 mintPrice = price;

        if(state == 1) {
            require(TBB_GENESIS.balanceOf(_msgSender()) > 0, "Must hold a genesis NFT");
            mintPrice = holderPrice;
        } else {
            if(state == 2 || state == 3) {
                bool isal = isAllowListed(_msgSender(), _merkleProof);
                if(state == 2) {
                    require(isal, "Allow list only");
                }
                if(isal) {
                    mintPrice = alPrice;
                }
            }
        }

        require(msg.value == mintPrice * amount, "incorrect amount of ETH sent");
        
        _safeMint(_msgSender(), amount);
        emit minted(_msgSender(), msg.value, _msgSender(), amount);
    }

    function ownerMint(uint amount, address _recipient) external onlyAdmin {
        require(totalSupply() + amount <= maxSupply,  "exceeds max supply");
        _safeMint(_recipient, amount);
        emit minted(_msgSender(), 0, _recipient, amount);
    }

    // Add amount and address parameters
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success,) = _msgSender().call{value: balance}("");
        require(success, "Transfer fail");
    }

    function setURI(string memory _uri) external onlyOwner {
        URI = _uri;
    }

    function setState(uint256 _state) external onlyAdmin {
        require(_state <= 3, "State can only be 0, 1, 2, 3");
        state = _state;
        emit stateChanged(state);
    }

    function setHolderPrice(uint256 _holderPrice) external onlyOwner {
        holderPrice = _holderPrice;
    }

    function setMaxPerTx(uint256 _maxPerTx) external onlyAdmin {
        maxPerTx = _maxPerTx;
    }
    
    function setALRoot(bytes32 root) external onlyAdmin {
        alRoot = root;
    }

    function splitWithdraw() external onlyAdmin nonReentrant{
        uint256 balance = address(this).balance;

        uint256 payout1 = percentageOf(balance, wallets[0].percentage);
        (bool success1,) = wallets[0].wallet.call{value: payout1 }("");
        require(success1, 'Transfer fail');
        
        uint256 payout2 = percentageOf(balance, wallets[1].percentage);
        (bool success2,) = wallets[1].wallet.call{value: payout2 }("");
        require(success2, 'Transfer fail');

        uint256 payout3 = percentageOf(balance, wallets[2].percentage);
        (bool success3,) = wallets[2].wallet.call{value: payout3 }("");
        require(success3, 'Transfer fail');
        
        uint256 payout4 = percentageOf(balance, wallets[3].percentage);
        (bool success4,) = wallets[3].wallet.call{value: payout4 }("");
        require(success4, 'Transfer fail');

        uint256 payout5 = percentageOf(balance, wallets[4].percentage);
        (bool success5,) = wallets[4].wallet.call{value: payout5 }("");
        require(success5, 'Transfer fail');

        uint256 payout6 = percentageOf(balance, wallets[5].percentage);
        (bool success6,) = wallets[5].wallet.call{value: payout6 }("");
        require(success6, 'Transfer fail');

        uint256 payout7 = percentageOf(balance, wallets[6].percentage);
        (bool success7,) = wallets[6].wallet.call{value: payout7 }("");
        require(success7, 'Transfer fail');
    }

    function setGenesis(address _genesis) external onlyOwner {
        TBB_GENESIS = ERC721A(_genesis);
    }

    function changePaySplits(uint256 indexToChange, uint256 _percentage, address payable _wallet) external onlyOwner {
        wallets[indexToChange].percentage = _percentage;
        wallets[indexToChange].wallet = _wallet;
    }

    function addAdmin(address _adm) external onlyOwner {
        isAdmin[_adm] = true;
    }

    function revokeAdmin(address _adm) external onlyOwner {
        isAdmin[_adm] = false;
    }
}