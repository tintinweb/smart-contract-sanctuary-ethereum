// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

contract SimpleRep {
    event DomainCreated(uint256 DomainId);
    event ActorRated(
        uint256 DomainId,
        address RatorAddress,
        address RateeAddress,
        uint256 Amount
    );
    event BoostrappedActor(
        uint256 DomainId,
        address RecipientAddress,
        uint256 Amount
    );
    error InsufficientRatingTokens();

    /// @dev Domain struct
    /// @param id Domain id
    /// @param ratingTokenSupply Total rating tokens allowed in the domain
    struct Domain {
        uint256 id;
        uint256 ratingTokenSupply;
        uint256 repDecaySpeed;
        address creator;
    }

    /// @dev Representation of an Actor in storage.
    /// @param reputationScore the current reputation of some Actor, with respect to some subject
    /// @param ratingBalance the current balance of some Actor's rating tokens
    /// @param lastUpdated when the Actor was last updated
    struct Actor {
        uint256 reputationScore;
        uint256 ratingBalance;
        uint256 lastUpdated;
    }

    mapping(uint256 => Domain) public domains;

    mapping(uint256 => mapping(address => Actor)) actors;

    uint256 public nextDomainId = 0;

    /** @notice Create a domain specific reputation system
        @param _ratingTokenSupply The total supply of the rating token
        @param _repDecaySpeed The speed at which reputation decays */
    function createDomain(
        uint256 _ratingTokenSupply,
        uint256 _repDecaySpeed
    ) external {
        Domain memory domain = Domain({
            id: nextDomainId,
            ratingTokenSupply: _ratingTokenSupply,
            repDecaySpeed: _repDecaySpeed,
            creator: msg.sender
        });
        domains[nextDomainId] = domain;
        emit DomainCreated(nextDomainId);

        actors[nextDomainId][msg.sender] = Actor({
            reputationScore: _ratingTokenSupply,
            ratingBalance: _ratingTokenSupply,
            lastUpdated: block.timestamp
        });
        nextDomainId += 1;
    }

    /// @notice Refill the rating token supply of a domain to the creator for distribution
    /// @param _domainId The reputation domain
    /// @param _amount The amount of the rating token to give to the creator
    /// @param _recipientAddress The address of the recipient
    function bootstrapDomainAddress(
        uint256 _domainId,
        uint256 _amount,
        address _recipientAddress
    ) external {
        Domain memory domain = domains[_domainId];
        require(
            msg.sender == domain.creator,
            "Only the creator can refill the domain"
        );
        Actor memory actor = actors[_domainId][_recipientAddress];
        require(
            actor.ratingBalance + _amount <= domain.ratingTokenSupply,
            "Cannot refill more than the total supply"
        );
        actors[_domainId][_recipientAddress].ratingBalance += _amount;
        emit BoostrappedActor(_domainId, _recipientAddress, _amount);
    }

    /// @notice Rate another actor in your domain
    /// @param _domainId The reputation domain ID
    /// @param _amount The amount to rate
    function rate(
        uint256 _domainId,
        uint256 _amount,
        address _rateeAddress
    ) external {
        require(msg.sender != _rateeAddress, "Cannot rate yourself");

        Actor memory rater = actors[_domainId][msg.sender];
        if (rater.ratingBalance < _amount) revert InsufficientRatingTokens();

        Domain memory domain = domains[_domainId];
        Actor memory ratee = actors[_domainId][_rateeAddress];

        // Decay the reputation of the rater
        rater = updateActor(rater, domain);

        // Decay the reputation of the ratee
        ratee = updateActor(ratee, domain);
        
        // Subtract the rating tokens from the rater
        rater.ratingBalance -= _amount;
        actors[_domainId][msg.sender] = rater;

        // Update the reputation of the ratee
        ratee.reputationScore += _amount;
        actors[_domainId][_rateeAddress] = ratee;

        emit ActorRated(_domainId, msg.sender, _rateeAddress, _amount);
    }

    /// @notice Update the reputation of an actor after decay and when it was last updated
    /// @param _actor The actor to update
    /// @param _domainId The domain ID of the actor
    function updateActor(
        Actor memory _actor,
        Domain memory _domainId
    ) private view returns (Actor memory) {
        uint256 timeDelta;
        uint256 repToSubtract;
        if (_actor.lastUpdated != 0)
            timeDelta = block.timestamp - _actor.lastUpdated;
        repToSubtract = _domainId.repDecaySpeed * timeDelta;
        if (repToSubtract > _actor.reputationScore) {
            _actor.reputationScore = 0;
        } else {
            _actor.reputationScore -= repToSubtract;
        }
        _actor.lastUpdated = block.timestamp;
        return _actor;
    }

    /// @notice Get the rating token balance of an actor
    function getRatingBalance(
        uint256 _domainId,
        address _address
    ) external view returns (uint256) {
        return getActor(_domainId, _address).ratingBalance;
    }

    /// @notice Get the reputation score of an actor
    function getReputationScore(
        uint256 _domainId,
        address _address
    ) external view returns (uint256) {
        return getActor(_domainId, _address).reputationScore;
    }

    function getActor(
        uint256 _domainId,
        address _address
    ) public view returns (Actor memory actor) {
        Actor memory staleActor = actors[_domainId][_address];
        Domain memory domain = domains[_domainId];
        return updateActor(staleActor, domain);
    }
}