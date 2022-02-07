// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

//··········································
//··········································
//········_________·___·___····_________····
//······/  ______  \\  \\  \·/  ______  \···
//·····/__/·····/  //  //  //__/·····/  /···
//····_________/  //  //  /_________/  /····
//···/  _________//  //  //  _________/·····
//··/  /________ /  //  //  /________·······
//·/__/\_______//__//__//__/\_______/·∅·RUN·
//··········································
//··········································

import "./ERC1155.sol";
import "./AbstractMintPassFactory.sol";
import "./PaymentSplitter.sol";
import "./MerkleProof.sol";


contract MintPassFactory is AbstractMintPassFactory, PaymentSplitter  {
    uint private mpCounter = 1; 
    uint private bCounter = 1; 

    // root hash of merkle tree generated offchain of all whitelisted addresses
    // provide as byte32 type, not string. 0x prefix required.
    bytes32 public merkleRoot1;
    bytes32 public merkleRoot2;
    bytes32 public merkleRoot3;
    bytes32 public merkleRoot4;
  
    // new mint passes can be added to support future collections
    mapping(uint256 => MintPass) public MintPasses;
    mapping(uint256 => Bundle) public Bundles;

    // track claimed whitelist ==> bundles minted
    mapping(address => uint) public Whitelist;

    // sale state 
    uint public saleState = 0;
    uint public promoClaims = 60;
    uint public claimMax = 2;   //wl max
    uint public publicMax = 5;  // public max

    struct MintPass {
        uint256 quantity;
        string name;
        address redeemableContract; 
        string uri;
    }

    struct Bundle {
        uint256 price;
        uint256 quantity;
        string name;
    }    

    constructor(
        string memory _name, 
        string memory _symbol,
        address[] memory _payees,
        uint256[] memory _paymentShares
    ) ERC1155("https://mint.2112.run/tokens/") PaymentSplitter(_payees, _paymentShares) {
        name_ = _name;
        symbol_ = _symbol;
        // add the bundles
        addBundle(.2112 ether, 7000, "LOW"); //only 7000 not 7060 so promos are extra
        addBundle(.6 ether,    3000, "MID");
        addBundle(1.2 ether,   500, "HIGH");
        // add the MP
        addMintPass(10560, "Cryptorunner", msg.sender,          "https://mint.2112.run/tokens/1.json");
        addMintPass(7060,  "Land Standared Tier", msg.sender,   "https://mint.2112.run/tokens/2.json");
        addMintPass(3000,  "Land Rare Tier", msg.sender,        "https://mint.2112.run/tokens/3.json");
        addMintPass(500,   "Land Epic Tier ", msg.sender,       "https://mint.2112.run/tokens/4.json");
        addMintPass(7060,  "Console Standard Tier", msg.sender, "https://mint.2112.run/tokens/5.json");
        addMintPass(3000,  "Console Rare Tier", msg.sender,     "https://mint.2112.run/tokens/6.json");
        addMintPass(500,   "Console Epic Tier", msg.sender,     "https://mint.2112.run/tokens/7.json");

    } 

    function addMintPass(
        uint256  _quantity, 
        string memory _name,
        address _redeemableContract,
        string memory _uri

    ) public onlyOwner {

        MintPass storage mp = MintPasses[mpCounter];
        mp.quantity = _quantity;
        mp.redeemableContract = _redeemableContract;
        mp.name = _name;
        mp.uri = _uri;
        mpCounter += 1;
    }

    function editMintPass(
        uint256 _quantity, 
        string memory _name,        
        address _redeemableContract, 
        uint256 _mpIndex,
        string memory _uri
    ) external onlyOwner {

        MintPasses[_mpIndex].quantity = _quantity;    
        MintPasses[_mpIndex].name = _name;    
        MintPasses[_mpIndex].redeemableContract = _redeemableContract;  
        MintPasses[_mpIndex].uri = _uri;    
    }     


    function addBundle (
        uint256 _bundlePrice,
        uint256 _bundleQty,
        string memory _name
    ) public onlyOwner {
        require(_bundlePrice > 0, "addBundle: bundle price must be greater than 0");
        require(_bundleQty > 0, "addBundle: bundle quantity must be greater than 0");

        Bundle storage b = Bundles[bCounter];
        b.price = _bundlePrice;
        b.quantity = _bundleQty;
        b.name = _name;

        bCounter += 1;
    }

    function editBundle (
        uint256 _bundlePrice,
        uint256 _bundleQty,
        string memory _name,
        uint256 _bundleIndex
    ) external onlyOwner {
        require(_bundlePrice > 0, "editBundle: bundle price must be greater than 0");
        require(_bundleQty > 0, "editBundle: bundle quantity must be greater than 0");

        Bundles[_bundleIndex].price = _bundlePrice;
        Bundles[_bundleIndex].quantity = _bundleQty;
        Bundles[_bundleIndex].name = _name;
    }

    function burnFromRedeem(
        address account, 
        uint256[] calldata ids, 
        uint256[] calldata amounts
    ) external {
        for (uint i = 0; i < ids.length; i++) {
            require(MintPasses[ids[i]].redeemableContract == msg.sender, "Burnable: Only allowed from redeemable contract");
        }
        _burnBatch(account, ids, amounts);
    }  


    // mint a pass
    function claim(
        // list of quantities for each bundle [b1,b2,b3]
        // eg. [0,2,1]
        uint[] calldata _quantities,
        bytes32[] calldata _merkleProof
    ) external payable {
        // verify contract is not paused
        require(saleState > 0, "Claim: claiming is paused");
        // Verify minting price
        require(msg.value >= 
            (Bundles[1].price * _quantities[0])
            + (Bundles[2].price * _quantities[1])
            + (Bundles[3].price * _quantities[2])
            , "Claim: Insufficient ether submitted.");

        // Verify quantity is within remaining available 
        require(Bundles[1].quantity - _quantities[0] >= 0, "Claim: Not enough bundle1 quantity");
        require(Bundles[2].quantity - _quantities[1] >= 0, "Claim: Not enough bundle2 quantity");
        require(Bundles[3].quantity - _quantities[2] >= 0, "Claim: Not enough bundle3 quantity");

        // Verify on whitelist if not public sale
        // warning: Whitelist[msg.sender] will return 0 if not on whitelist
        if (saleState > 0 && saleState < 5) {

            require(
                Whitelist[msg.sender] 
                    + _quantities[0] +  _quantities[1] + _quantities[2]
                    <= claimMax
            
                , "Claim: Quantites exceed whitelist max allowed."
            );
            // verify the provided _merkleProof matches
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            if (saleState == 1){
                require(MerkleProof.verify(_merkleProof, merkleRoot1, leaf), 'Not on whitelist (Merkle Proof 1 fail).');
            } else if (saleState == 2) {
                require(MerkleProof.verify(_merkleProof, merkleRoot2, leaf), 'Not on whitelist (Merkle Proof 2 fail).');
            } else if (saleState == 3) {
                require(MerkleProof.verify(_merkleProof, merkleRoot3, leaf), 'Not on whitelist (Merkle Proof 3 fail).');
            } else if (saleState == 4) {
                require(MerkleProof.verify(_merkleProof, merkleRoot4, leaf), 'Not on whitelist (Merkle Proof 4 fail).');
            }

            // passed; update Whitelist qty
            Whitelist[msg.sender] = Whitelist[msg.sender] + _quantities[0] +  _quantities[1] + _quantities[2];
        }
        else if (saleState == 5) {
            // block proxy contract minting
            require(msg.sender == tx.origin, 'msg.sender does not match tx.origin');
            // public sale, max mint per txn
            require(_quantities[0] +  _quantities[1] + _quantities[2] 
            <= publicMax, "Claim: Quantities exceed mint max allowed.");
        }
        
        // pass ==> mint
        // memory arrays can only be fixed size
        uint size = 1;
        for (uint i = 0; i < 3; i++) {
            if(_quantities[i] > 0) {
                size = size + 2;
            }
        }

        uint256[] memory qtys = new uint256[](size);
        uint256[] memory ids = new uint256[](size);
        ids[0] = 1;
        uint next = 1;

        // bundle1 gets MPs 1,2,5
        if (_quantities[0] > 0) {
            qtys[0] = qtys[0] + _quantities[0];
            qtys[next] = _quantities[0];
            ids[next] = 2;
            next += 1;
            qtys[next] = _quantities[0];
            ids[next] = 5;
            next += 1;
            Bundles[1].quantity -= _quantities[0];
            
        }
        // bundle2 gets MPs 1, 3, 6
        if (_quantities[1] > 0) {
            qtys[0] = qtys[0] + _quantities[1];
            qtys[next] = _quantities[1];
            ids[next] = 3;
            next += 1;
            qtys[next] = _quantities[1];
            ids[next] = 6;
            next += 1;
            Bundles[2].quantity -= _quantities[1];

        }

        // bundle3 gets MPS 1, 4, 7
        if (_quantities[2] > 0) {
            qtys[0] = qtys[0] + _quantities[2];
            qtys[next] = _quantities[2];
            ids[next] = 4;
            next += 1;
            qtys[next] = _quantities[2];
            ids[next] = 7;
            next += 1;
            Bundles[3].quantity -= _quantities[2];

        }
        
        _mintBatch(msg.sender, ids, qtys, "");

    }

    // owner can send up to 60 promo bundle1
    // we bypass bundle1.quantity so we get 60 EXTRA!
    function promoClaim(address _to, uint _quantity) external onlyOwner {
        require(promoClaims - _quantity >= 0, "Quantity exceeds available promos remaining. ");
        promoClaims -= _quantity;
        // one cryptorunner, one land, one item
        uint256[] memory y = new uint256[](3);
        y[0] = 1;
        y[1] = 2;
        y[2] = 5;
        uint256[] memory x = new uint256[](3);
        x[0] = _quantity;
        x[1] = _quantity;
        x[2] = _quantity;
        _mintBatch(_to, y, x, "");
    }

    // owner can update sale state
    function updateSaleStatus(uint _saleState) external onlyOwner {
        require(_saleState <= 5, "updateSaleStatus: saleState must be between 0 and 5");
        saleState = _saleState;
    }

    // owner can update wl claimMax
    function updateClaimMax(uint _claimMax) external onlyOwner {
        require(_claimMax >= 0, "claimMax: claimMax must be greater than, or equal to 0");
        claimMax = _claimMax;
    }

    // owner can update public claimMax
    function updatePublicMax(uint _publicMax) external onlyOwner {
        require(_publicMax >= 0, "publicMax: publicMax must be greater than, or equal to 0");
        publicMax = _publicMax; 
    }

    // token uri
    function uri(uint256 _id) public view override returns (string memory) {
        //require(MintPasses[_id] >= 0, "URI: nonexistent token");
        return string(MintPasses[_id].uri);
    }    

    // owner can update the merkleRoot;
    // 0x prepend required
    function updateMerkleRoot(bytes32 _merkleRoot, uint number) external onlyOwner {
        if (number == 1 ) {
            merkleRoot1 = _merkleRoot;
        } else if (number == 2) {
            merkleRoot2 = _merkleRoot;
        } else if (number == 3) {
            merkleRoot3 = _merkleRoot;
        } else if (number == 4) {
            merkleRoot4 = _merkleRoot;
        }
        else {
            require(false, "updateMerkleRoot: number must be between 1 and 4");
        }
    }
}