pragma solidity ^0.8.0;
import "./interfaces/IGENIPass.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./utils/PermissionGroupUpgradeable.sol";
import "./interfaces/IExchangeRouter.sol";
import "./interfaces/IGEMUNILeasing.sol";

contract GEMUNILeasing is PermissionGroupUpgradeable, IGEMUNILeasing {
    address public geniPass;
    IERC20 public geni;

    address public treasury;
    uint private constant weekPerSecond = 604800;
    
    address public busd;
    address public exchange;

    mapping(address => mapping(uint => LeasingInfo)) public leasingInfo;
    mapping(address => mapping(uint => LeasingGuildInfo)) public leasingGuildInfo;
    mapping(address => mapping(uint => RenterInfo)) public renterInfo;
    mapping(address => bool) public gameGuild;
    mapping(address => bool) public listNFTSupport;

    function _initialize (
        IERC20 geniAddr,
        address geniPassAddr,
        address _treasury,
        address _busd,
        address _exchange
    ) external initializer {
        __operatable_init();
        geni = geniAddr;
        geniPass = geniPassAddr;
        treasury = _treasury;
        busd = _busd;
        exchange = _exchange;
    }

    function setInput(address _geniPass, address _treasury, address _exchange, address _geni, address _busd) external onlyOperator {
        require(_treasury != address(0) && _geniPass != address(0) && _exchange != address(0) && _geni != address(0) && _busd != address(0), "Leasing: invalid address");
        treasury = _treasury;
        geniPass = _geniPass;
        exchange = _exchange;
        geni = IERC20(_geni);
        busd = _busd;
        emit SetInput(_geniPass, _treasury, _exchange);
    }

    function addListTokens(address _nftToken) external onlyOperator {
        require(_nftToken != address(0) && !listNFTSupport[_nftToken], "GENIPassSale: invalid address");
        listNFTSupport[_nftToken] = true;
        emit AddListTokens(_nftToken);
    }

    function removeListTokens(address  _nftToken) external onlyOperator {
        require(_nftToken != address(0) && listNFTSupport[ _nftToken], "GENIPassSale: invalid address");
        listNFTSupport[_nftToken] = false;
        emit RemoveListTokens( _nftToken);
    }

    function convertPrice(uint busdPrice) public view returns(uint geniPrice) {
        address[] memory pair = new address[](2);
        (pair[0], pair[1]) = (busd, address(geni));
        uint256[] memory amounts = IExchangeRouter(exchange).getAmountsOut(busdPrice, pair);
        geniPrice = amounts[1];
    }

    function putOnLeasing(LeasingCreate[] memory inputs) public override {
        for (uint i = 0; i < inputs.length; i++) {
            address nftToken = inputs[i].nftToken;
            uint tokenId = inputs[i].tokenId;
            uint pricePerWeek = inputs[i].pricePerWeek;
            uint minDuration = inputs[i].minDuration;
            uint maxDuration = inputs[i].maxDuration;
            uint mortgageAmount = inputs[i].mortgageAmount;
            LeasingInfo storage leasing = leasingInfo[nftToken][tokenId];
            RenterInfo memory renter = renterInfo[nftToken][tokenId];
            LeasingGuildInfo storage leasingGuild = leasingGuildInfo[nftToken][tokenId];
            require(nftToken != address(0) && minDuration > 0 && maxDuration >= minDuration && pricePerWeek > 0, "Leasing: invalid input");
            if (nftToken != geniPass && leasingGuild.gameGuild == address(0)) {
                require(listNFTSupport[nftToken], "Leasing: invalid token");
                require(mortgageAmount > 0, "Leasing: invalid mortgage amount");
            } else {
                require(mortgageAmount == 0, "Leasing: invalid mortgage amount");
            }
            address lender;
            //admin put, user put, guild put
            if (!gameGuild[msg.sender] || gameGuild[msg.sender] && leasing.lender == address(0) && renter.renter == address(0)) {
                if (nftToken != geniPass) {
                    address lenderAddress = leasingInfo[nftToken][tokenId].lender;
                    address guildAddress = leasingGuildInfo[nftToken][tokenId].gameGuild;
                    require(lenderAddress == address(0) && guildAddress == address(0),"Leasing: Token already rented");
                }
                leasing.lender = operators[msg.sender] ? treasury :  msg.sender;
                leasing.price = pricePerWeek;
                leasing.minDuration = minDuration;
                leasing.maxDuration = maxDuration;
                leasing.mortgageAmount = mortgageAmount;
                lender = leasing.lender;
            //admin put -> guild rent -> guild put
            //user put -> guild rent -> guild put
            } else {
                require(msg.sender == leasingGuild.gameGuild && leasingGuild.price == 0, "Leasing: invalid sender or already put on lending");
                if (leasing.lender != address(0)) {
                    require(block.timestamp <= leasingGuild.startLending + leasingGuild.duration * weekPerSecond, "Leasing: overtime");
                    if (nftToken == geniPass) {
                        if(IGENIPass(nftToken).isLocked(tokenId)) {
                            IGENIPass(geniPass).unLockPass(tokenId);
                            IGENIPass(geniPass).setActive(tokenId, false);
                        }
                    } else {
                        geni.transfer(msg.sender, leasing.mortgageAmount);
                    }
                }

                leasingGuild.price = pricePerWeek;
                leasingGuild.minDuration = minDuration;
                leasingGuild.maxDuration = maxDuration;
                leasingGuild.mortgageAmount = mortgageAmount;

                lender = leasingGuild.gameGuild;
            }
            IERC721(nftToken).transferFrom(msg.sender, address(this), tokenId);
            emit PutOnLeasing(nftToken, tokenId, minDuration, maxDuration, pricePerWeek, lender, mortgageAmount);
        }
    }

    function registerLeasing(LeasingRegister[] memory inputs, uint rentalPrice) external override {
        require(gameGuild[msg.sender], "Leasing: not game guild");
        uint totalRental;
        for( uint i = 0; i < inputs.length; i++) {
            address nftToken = inputs[i].nftToken;
            uint tokenId = inputs[i].tokenId;
            uint pricePerWeek = inputs[i].pricePerWeek;
            uint minDuration = inputs[i].minDuration;
            uint maxDuration = inputs[i].maxDuration;
            uint duration = inputs[i].duration;
            totalRental += register(nftToken, tokenId, duration, minDuration, maxDuration, pricePerWeek);
        }
        require(rentalPrice == totalRental, "Leasing: invalid price");
    }

    function register(address nftToken, uint tokenId, uint duration, uint minDuration, uint maxDuration, uint pricePerWeek) internal returns (uint rentalAmount) {
        LeasingInfo storage leasing = leasingInfo[nftToken][tokenId];
        LeasingGuildInfo storage leasingGuild = leasingGuildInfo[nftToken][tokenId];
        RenterInfo memory renter = renterInfo[nftToken][tokenId];
        uint min = leasing.minDuration;
        uint max = leasing.maxDuration;
        rentalAmount = leasing.price * duration;
        uint geniRental = convertPrice(rentalAmount);
        geni.transferFrom(msg.sender, leasing.lender, geniRental);
        // admin put, user put, guild put (not guild ren then put)
        require(
            leasing.lender != address(0) && 
            msg.sender != leasing.lender &&
            leasingGuild.gameGuild == address(0) && 
            renter.renter == address (0), 
            "Leasing: invalid token"
        );
        require(duration >= min && duration <= max, "Leasing: invalid duration");

        require(minDuration > 0 && maxDuration >= minDuration && pricePerWeek > 0, "Leasing: invalid input");

        leasingGuild.gameGuild = msg.sender;
        leasingGuild.duration = duration;
        leasingGuild.startLending = block.timestamp;

        leasingGuild.price = pricePerWeek;
        leasingGuild.minDuration = minDuration;
        leasingGuild.maxDuration = maxDuration;
        emit RegisterLeasing(nftToken, tokenId, duration, minDuration, maxDuration, pricePerWeek, geniRental, leasingGuild.startLending);
    }

    function updateLeasing(address nftToken, uint tokenId, uint newMinDuration, uint newMaxDuration, uint newPricePerWeek) external override {
        LeasingInfo storage leasing = leasingInfo[nftToken][tokenId];
        LeasingGuildInfo storage guild = leasingGuildInfo[nftToken][tokenId];
        RenterInfo memory renter = renterInfo[nftToken][tokenId];
        require(newMinDuration > 0 && newMaxDuration >= newMinDuration && newPricePerWeek > 0, "Leasing: invalid input");
        require(IERC721(nftToken).ownerOf(tokenId) == address(this) && renter.renter == address(0), "Leasing: already rented or not lending");
        if (msg.sender == guild.gameGuild) {
            require(block.timestamp <= guild.startLending + guild.duration * weekPerSecond, "Leasing: overtime");
            guild.minDuration = newMinDuration;
            guild.maxDuration = newMaxDuration;
            guild.price = newPricePerWeek;
        } else if (operators[msg.sender] || msg.sender == leasing.lender && leasing.lender != treasury) {
            require(leasing.price > 0, "Leasing: not on lending");
            require(guild.gameGuild == address(0), "Leasing: already registered");
            leasing.minDuration = newMinDuration;
            leasing.maxDuration = newMaxDuration;
            leasing.price = newPricePerWeek;
        } else {
            revert("Leasing: invalid sender");
        }
        emit UpdateLeasing(nftToken, tokenId, newMinDuration, newMaxDuration, newPricePerWeek);
    }
    
    function cancelLeasing(address nftToken, uint tokenId, bytes memory sig) external override {
        LeasingInfo memory leasing = leasingInfo[nftToken][tokenId];
        LeasingGuildInfo storage guild = leasingGuildInfo[nftToken][tokenId];
        RenterInfo memory renter = renterInfo[nftToken][tokenId];
        require(
            IERC721(nftToken).ownerOf(tokenId) == address(this) && 
            renter.renter == address(0), 
            "Leasing: already rented"
        );
        if (msg.sender == guild.gameGuild) {
            if (guild.duration != 0 && block.timestamp > guild.startLending + guild.duration * weekPerSecond) {
                delete leasingGuildInfo[nftToken][tokenId];
            } else {
                IERC721(nftToken).transferFrom(address(this), guild.gameGuild, tokenId);
                if (nftToken == geniPass) {
                    if(IERC721(geniPass).getApproved(tokenId) != address(this) && !IERC721(geniPass).isApprovedForAll(msg.sender, address(this))) {
                        IGENIPass(geniPass).permit(msg.sender, address(this), tokenId, sig);
                    }
                    IGENIPass(geniPass).setActive(tokenId, true);

                    if(!IGENIPass(geniPass).isLocked(tokenId)) {
                        IGENIPass(geniPass).lockPass(tokenId);
                    }
                } else {
                    geni.transferFrom(msg.sender, address(this), leasing.mortgageAmount);
                }
                guild.minDuration = 0;
                guild.maxDuration = 0;
                guild.mortgageAmount = 0;
                guild.price = 0;
            }
        } else if (operators[msg.sender] || msg.sender == leasing.lender && leasing.lender != treasury) {
            require(leasing.price > 0, "Leasing: not on lending");
            require(guild.gameGuild == address(0), "Leasing: already registered");
            IERC721(nftToken).transferFrom(address(this), msg.sender, tokenId);
            delete leasingInfo[nftToken][tokenId];
        } else {
            revert("Leasing: invalid sender");
        }
 
        emit CancelLeasing(nftToken, tokenId);
    }

    function addListGameGuild(address[] memory users) external override onlyOperator {
        for (uint i = 0; i < users.length; i++) {
            require(!gameGuild[users[i]]);
            require(users[i] != address(0), "Leasing: invalid address");
            gameGuild[users[i]] = true;
        }
        emit AddListGameGuild(users);
    }

    function removeFromGuilds(address[] calldata users) external override onlyOperator {
        for (uint i; i < users.length; i++) {
            require(gameGuild[users[i]]);
            gameGuild[users[i]] = false;
        }
        emit RemoveFromGuild(users);
    }

    function rent(address nftToken, uint tokenId, uint duration, uint price, bytes memory sig) external override {
        LeasingInfo storage leasing = leasingInfo[nftToken][tokenId];
        LeasingGuildInfo storage guild = leasingGuildInfo[nftToken][tokenId];
        RenterInfo storage renter = renterInfo[nftToken][tokenId];

        require(renter.renter == address(0) && leasing.lender != address(0), "Leasing: not on leasing or already rented");
        uint rentalPriceGeni;
        address lender;
        uint startLending;
        if (guild.gameGuild != address(0)) {
            require(guild.price > 0, "Leasing: already rented");
            require( block.timestamp + duration * weekPerSecond <= guild.startLending + guild.duration * weekPerSecond, "Leasing: invalid duration");
            lender = guild.gameGuild;
            rentalPriceGeni = rentFromGameGuild(guild, duration, price, leasing.lender);
        } else {
            lender = leasing.lender;
            rentalPriceGeni = rentFromLeaser(leasing, duration, price);
        } 

        IERC721(nftToken).transferFrom(address(this), msg.sender, tokenId);

        if (nftToken == geniPass) {
            if(IERC721(geniPass).getApproved(tokenId) != address(this) && !IERC721(geniPass).isApprovedForAll(msg.sender, address(this))) {
                IGENIPass(geniPass).permit(msg.sender, address(this), tokenId, sig);
            }
            IGENIPass(geniPass).setActive(tokenId, true);

            if(!IGENIPass(geniPass).isLocked(tokenId)) {

                IGENIPass(geniPass).lockPass(tokenId);
            }
        } else {
            require(listNFTSupport[nftToken], "Leasing: invalid token");
            geni.transferFrom(msg.sender, address(this), leasing.mortgageAmount);
        }
        if (gameGuild[msg.sender]) {
            require(guild.duration == 0, "Leasing: Token already rented");
            guild.gameGuild = msg.sender;
            guild.startLending = block.timestamp;
            guild.duration = duration;
            startLending = guild.startLending;
        } else { 
            renter.renter = msg.sender;
            renter.startLending = block.timestamp;
            renter.duration = duration;
            startLending = renter.startLending;
        }
        emit Rent(nftToken, tokenId, rentalPriceGeni, startLending, duration, lender, msg.sender);
    }

    function rentFromGameGuild(LeasingGuildInfo storage guild, uint duration, uint price, address lender) internal returns(uint rentalPriceGeni) {
        require(msg.sender != guild.gameGuild && msg.sender != lender, "Leasing: Lender can not rent");
        require(
            duration >= guild.minDuration && 
            duration <= guild.maxDuration,
            "Leasing: invalid duration"
        );
        uint rentalPrice = guild.price * duration;
        require(price == rentalPrice, "Leasing: invalid price");
        rentalPriceGeni = convertPrice(rentalPrice);
        
        geni.transferFrom(msg.sender, guild.gameGuild, rentalPriceGeni);
    }

    function rentFromLeaser(LeasingInfo storage leasing, uint duration, uint price) internal returns(uint rentalPriceGeni) {
        require(msg.sender != leasing.lender && duration >= leasing.minDuration && duration <= leasing.maxDuration, "Leasing: invalid sender or duration");
        uint rentalPrice = leasing.price * duration;
        require(price == rentalPrice, "Leasing: invalid price");
        rentalPriceGeni = convertPrice(rentalPrice);

        geni.transferFrom(msg.sender, leasing.lender, rentalPriceGeni);
    }


    function rentMore(address nftToken, uint tokenId, uint addedDuration, uint addedRentalPrice) external override {
        LeasingInfo storage leasing = leasingInfo[nftToken][tokenId];
        RenterInfo storage renter = renterInfo[nftToken][tokenId];
        LeasingGuildInfo storage guild = leasingGuildInfo[nftToken][tokenId];
        require(leasing.lender != address(0), "Leasing: not lending");
        require(addedDuration > 0,"Leasing: invalid added duration");
        uint addedAmount;
        address lender;
        if (msg.sender == renter.renter && guild.gameGuild != address(0)) {
            uint endLending = guild.startLending + guild.duration * weekPerSecond;
            require(block.timestamp <= endLending, "Leasing: overtime");
            uint endLendingMore = renter.startLending + (renter.duration + addedDuration) * weekPerSecond;
            require(
                endLendingMore <= guild.startLending + guild.duration * weekPerSecond, 
                "Leasing: invalid duration"
            );
            require(renter.duration + addedDuration <= guild.maxDuration, "Leasing: invalid duration");
            addedAmount = addedDuration * guild.price;
            renter.duration += addedDuration;
            lender = guild.gameGuild;
            
        } else if (msg.sender == guild.gameGuild || msg.sender == renter.renter) {
            addedAmount = addedDuration * leasing.price;
            lender = leasing.lender;
            if (msg.sender == guild.gameGuild) {
                require(guild.duration + addedDuration <= leasing.maxDuration, "Leasing: invalid duration");
                guild.duration += addedDuration;
            } else {
                require(renter.duration + addedDuration <= leasing.maxDuration, "Leasing: invalid duration");
                renter.duration += addedDuration;
            }
        } else {
            revert ("Leasing: invalid sender");
        }
        require(addedAmount == addedRentalPrice, "Leasing: invalid price");
        uint geniPrice = convertPrice(addedAmount);
        geni.transferFrom(msg.sender, lender, geniPrice);

        emit RentMore(nftToken, tokenId, geniPrice, addedDuration, lender , msg.sender);
    }

    function finishRenting(address nftToken, uint tokenId) external override {
        RenterInfo storage renter = renterInfo[nftToken][tokenId];
        LeasingInfo storage leasing = leasingInfo[nftToken][tokenId];
        LeasingGuildInfo storage guild = leasingGuildInfo[nftToken][tokenId];
        require(leasing.lender != address(0), "Leasing: not on leasing");
        require(msg.sender == guild.gameGuild || msg.sender == renter.renter, "Leasing: invalid renter");
        //guild return pass
        if (msg.sender == guild.gameGuild) {
            require(renter.renter == address(0), "Leasing: can not return");
            //guild register/rent+put -> lender
            if (guild.price != 0) {
                delete leasingGuildInfo[nftToken][tokenId];
            //guild rent -> lender
            } else {
                returnToLeaser(nftToken, tokenId, leasing.mortgageAmount, leasing.lender, guild.gameGuild);
                delete leasingGuildInfo[nftToken][tokenId];
            }
        //user return pass to lender/gameguild
        } else {
            returnToLeaser(nftToken, tokenId, leasing.mortgageAmount, leasing.lender, renter.renter);
            delete renterInfo[nftToken][tokenId];
        }
        emit FinishRenting(nftToken, tokenId, msg.sender);
    }

    function returnToLeaser(address nftToken, uint tokenId, uint mortgageAmount, address lender, address renter) internal {
        if (nftToken == geniPass) {
            IGENIPass(geniPass).unLockPass(tokenId);
            IGENIPass(geniPass).setActive(tokenId, false);
            IERC721(nftToken).transferFrom(renter, address(this), tokenId);
        } else {
            checkTransferNFT(nftToken, tokenId, mortgageAmount, lender, renter);
        }
    }

    function checkTransferNFT(address nftToken, uint tokenId, uint amount, address lender, address renter) internal {
        bool isStrictRecoverNFT;
        if (IERC721(nftToken).ownerOf(tokenId) == renter) {
            if (IERC721(nftToken).getApproved(tokenId) != address(this) && !IERC721(nftToken).isApprovedForAll(renter, address(this))) {
                isStrictRecoverNFT = true;
            }
        } else {
            isStrictRecoverNFT = false;
        }

        try IERC721(nftToken).transferFrom(renter, address(this), tokenId) {
            geni.transfer(renter, amount);
        } catch {
            if (isStrictRecoverNFT) {
                revert("Leasing: Cannot recover NFT");
            } else {
                LeasingInfo memory leasing = leasingInfo[nftToken][tokenId];
                LeasingGuildInfo memory guild = leasingGuildInfo[nftToken][tokenId];
                geni.transfer(lender, amount);
                if(leasing.lender != address (0) && guild.gameGuild != address (0)) {
                    delete leasingGuildInfo[nftToken][tokenId];
                }
                delete leasingInfo[nftToken][tokenId];
                emit CannotRecoverNFT(nftToken, tokenId);
            }
        }
    }

    function finishLeasing(address nftToken, uint[] memory tokenIds) external override {
        for (uint i = 0; i < tokenIds.length; i++) {
            RenterInfo storage renter = renterInfo[nftToken][tokenIds[i]];
            LeasingInfo storage leasing = leasingInfo[nftToken][tokenIds[i]];
            LeasingGuildInfo storage guild = leasingGuildInfo[nftToken][tokenIds[i]];
            require(
                msg.sender == guild.gameGuild || 
                operators[msg.sender] || 
                msg.sender == leasing.lender && 
                leasing.lender != treasury, 
                "Leasing: invalid sender"
            );
            require(renter.renter != address(0) || guild.gameGuild != address(0),"Leasing: no one rent");
            //guild retrieve NFT from renter
            if (msg.sender == guild.gameGuild) {
                guildRetrieveNFT(nftToken, tokenIds[i], renter, guild);
            //lender retrieve NFT
            } else if (operators[msg.sender] ||  msg.sender == leasing.lender && leasing.lender != treasury) {
                require(leasing.lender != address(0), "Leasing: not on leasing");
                lenderRetrieveNFT(nftToken, tokenIds[i], renter, leasing, guild);
            }
        }
    }

    function guildRetrieveNFT(address nftToken, uint tokenId, RenterInfo storage renter, LeasingGuildInfo storage guild) internal {
        require (renter.renter != address(0), "Leasing: user not rent");
        uint endLending = renter.startLending + renter.duration * weekPerSecond ;
        require (block.timestamp > endLending, "Leasing: can not be retrieve");
        LeasingInfo memory leasing = leasingInfo[nftToken][tokenId];
        address lenderAddress = guild.gameGuild;
        address renterAddress = renter.renter;
        if (nftToken == geniPass) {
            IGENIPass(geniPass).unLockPass(tokenId);
            IGENIPass(geniPass).setActive(tokenId, false);
            IERC721(nftToken).transferFrom(renter.renter, address(this), tokenId);
        } else {
            checkTransferNFT(nftToken, tokenId, leasing.mortgageAmount, leasing.lender, renter.renter);
        }
        delete renterInfo[nftToken][tokenId];
        emit FinishLeasing(nftToken, tokenId, renterAddress, lenderAddress);
    }

    function lenderRetrieveNFT(address nftToken,uint tokenId, RenterInfo storage renter, LeasingInfo storage leasing, LeasingGuildInfo storage guild) internal {
        address lenderAddress = leasing.lender;
        address renterAddress = renter.renter != address(0) && guild.gameGuild == address(0) ? renter.renter : guild.gameGuild;
        //lender retrieve pass from game guild, guild register/ rent+put/rent
        if (renter.renter == address(0) && guild.gameGuild != address(0)) {
            uint endLending = guild.startLending + guild.duration * weekPerSecond;
            require(block.timestamp > endLending, "Leasing: can not be retrieve");
            //guild register/rent + put
            if (guild.price > 0) {
                delete leasingGuildInfo[nftToken][tokenId];
            //guild rent
            } else {
                returnToLeaser(nftToken, tokenId, leasing.mortgageAmount, leasing.lender, guild.gameGuild);
                delete leasingGuildInfo[nftToken][tokenId];
            }
        //lender retrieve pass from renter, lender put -> guild register/ rent+put
        } else if (renter.renter != address(0) && guild.gameGuild != address(0)) {
            guildRegisterReturnNFT(nftToken, tokenId, renter, leasing, guild);
        //lender retrieve pass from renter, pass admin put
        } else if (renter.renter != address(0) && guild.gameGuild == address(0)) {
            leaserRetrieveNFT(nftToken, tokenId, renter, leasing);
        }
        emit FinishLeasing(nftToken, tokenId, renterAddress, lenderAddress);
    }

    function guildRegisterReturnNFT(address nftToken, uint tokenId, RenterInfo storage renter, LeasingInfo storage leasing, LeasingGuildInfo storage guild) internal {
        uint endLending =  guild.startLending + guild.duration * weekPerSecond ;
        require (block.timestamp > endLending, "Leasing: can not be retrieve");
        emit FinishLeasing(nftToken, tokenId, renter.renter, guild.gameGuild);
        if (nftToken == geniPass) {
            IGENIPass(geniPass).unLockPass(tokenId);
            IGENIPass(geniPass).setActive(tokenId, false);
            IERC721(nftToken).transferFrom(renter.renter, address(this), tokenId);
        } else {
            checkTransferNFT(nftToken, tokenId, leasing.mortgageAmount, leasing.lender, renter.renter);
        }
        delete renterInfo[nftToken][tokenId];
        delete leasingGuildInfo[nftToken][tokenId];
    }

    function leaserRetrieveNFT(address nftToken,uint tokenId, RenterInfo storage renter, LeasingInfo storage leasing) internal {
        uint endLending = renter.startLending + renter.duration * weekPerSecond;
        require (block.timestamp > endLending, "Leasing: can not be revoked");
        if (nftToken == geniPass) {
            IGENIPass(geniPass).unLockPass(tokenId);
            IGENIPass(geniPass).setActive(tokenId, false);
            IERC721(nftToken).transferFrom(renter.renter, address(this), tokenId);
        } else {
            checkTransferNFT(nftToken, tokenId, leasing.mortgageAmount, leasing.lender, renter.renter);
        }
        delete renterInfo[nftToken][tokenId];
    }

    function withdrawNFT(address nftToken, uint tokenId, address to) external onlyOperator {
        require(IERC721(nftToken).ownerOf(tokenId) == address(this), "Leasing: not found token");
        IERC721(nftToken).transferFrom(address(this), to, tokenId);
        if (nftToken == geniPass) {
            if(IGENIPass(geniPass).isLocked(tokenId)) {
                IGENIPass(geniPass).unLockPass(tokenId);
            }
        }
        emit WithdrawNFT(nftToken, tokenId);
    }

    function withdrawGeni(uint amount, address to) external onlyOperator {
        require(
            amount > 0 && 
            amount <= geni.balanceOf(address(this)) && 
            to != address(0),
            "Leasing: Invalid input"
        );
        geni.transfer(to, amount);
        emit WithdrawGeni(amount, treasury);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract PermissionGroupUpgradeable is OwnableUpgradeable {

    mapping(address => bool) public operators;
    event AddOperator(address newOperator);
    event RemoveOperator(address operator);

    function __operatable_init() internal initializer {
        __Ownable_init();
        operators[owner()] = true;
    }

    modifier onlyOperator {
        require(operators[msg.sender], "Operatable: caller is not the operator");
        _;
    }

    function addOperator(address operator) external onlyOwner {
        operators[operator] = true;
        emit AddOperator(operator);
    }

    function removeOperator(address operator) external onlyOwner {
        operators[operator] = false;
        emit RemoveOperator(operator);
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

interface IGENIPass is IERC721Upgradeable {
    enum PassType { Stone, Topaz, Citrine, Ruby, Diamond }
    enum PriceType { BNB, GENI }

    struct GeniPass {
        string serialNumber;
        PassType passType;
        bool isActive;
    }
    
    event SetActive(uint indexed passId, bool isActive);
    event PassCreated(address indexed owner, uint indexed passId, uint passType, string serialNumber);
    event LockPass(uint indexed passId);
    event UnLockPass(uint indexed passId);
    
    function burn(uint tokenId) external;
    
    function mint(address to, string memory serialNumber, PassType passType) external returns(uint tokenId);
    
    function getPass(uint passId) external view returns (GeniPass memory pass);

    function exists(uint passId) external view returns (bool);

    function setActive(uint tokenId, bool _isActive) external;

    function lockPass(uint passId) external;

    function unLockPass(uint passId) external;

    function permit(address owner, address spender, uint tokenId, bytes memory _signature) external;
    
    function isLocked(uint tokenId) external returns(bool);
}

pragma solidity ^0.8.0;

interface IGEMUNILeasing {
    struct LeasingInfo {
        address lender;
        uint price;
        uint minDuration;
        uint maxDuration;
        uint mortgageAmount;
    }

    struct LeasingGuildInfo {
        address gameGuild;
        uint price;
        uint minDuration;
        uint maxDuration;
        uint mortgageAmount;
        uint duration;
        uint startLending;
    }

    struct RenterInfo {
        address renter;
        uint duration;
        uint startLending;
    }

    struct LeasingCreate {
        address nftToken;
        uint tokenId;
        uint pricePerWeek;
        uint mortgageAmount;
        uint minDuration;
        uint maxDuration;
    }

    struct LeasingRegister {
        address nftToken;
        uint tokenId;
        uint pricePerWeek;
        uint minDuration;
        uint maxDuration;
        uint duration;
    }

    event PutOnLeasing(address nftToken, uint indexed tokenId, uint minDuration, uint maxDuration, uint pricePerweek, address lender, uint mortgageAmount);
    event RegisterLeasing(address nftToken, uint indexed tokenId, uint duration, uint minDuration, uint maxDuration, uint pricePerWeek, uint rentalPrice, uint startLending);
    event Rent(address nftToken, uint indexed tokenId, uint rentalPrice,uint startLending, uint duration, address lender, address renter);
    event RentMore(address nftToken, uint indexed tokenId, uint amount, uint duration, address lender, address renter);
    event FinishRenting(address nftToken, uint indexed tokenId, address renter);
    event FinishLeasing(address nftToken, uint indexed tokenIds, address renter, address lender);
    event UpdateLeasing(address nftToken, uint tokenId, uint newMinDuration, uint newMaxDuration, uint newPricePerWeek);
    event CancelLeasing(address nftToken, uint indexed tokenId);
    event CannotRecoverNFT(address nftToken, uint indexed tokenId);

    
    event SetInput(address _geniPass, address _treasury, address _exchange);
    event AddListGameGuild(address[] listGuilds);
    event RemoveFromGuild(address[] listGuilds);
    event AddListTokens(address token);
    event RemoveListTokens(address token);

    event WithdrawNFT(address nftToken, uint indexed tokenId);
    event WithdrawGeni(uint amount, address treasury);

    // function putOnLeasing(address nftToken, uint[] memory tokenId, uint minDuration, uint maxDuration, uint[] memory pricePerWeek, uint mortgageAmount) external;
    function putOnLeasing(LeasingCreate[] memory inputs) external;
    function registerLeasing(LeasingRegister[] memory inputs, uint rentalPrice) external;
    function rent(address nftToken, uint tokenId, uint duration, uint price, bytes memory sig) external;
    function rentMore(address nftToken, uint tokenId, uint addedDuration, uint addedRentalPrice) external;
    function finishRenting(address nftToken, uint tokenId) external;
    function finishLeasing(address nftToken, uint[] memory tokenId) external;


    function updateLeasing(address nftToken, uint tokenId, uint newMinDuration, uint newMaxDuration, uint newPricePerSecond) external;
    function cancelLeasing(address nftToken, uint tokenId, bytes memory sig) external;
    function addListGameGuild(address[] memory users) external;
    function removeFromGuilds(address[] calldata users) external;
}

//SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

interface IExchangeRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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
interface IERC165Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}