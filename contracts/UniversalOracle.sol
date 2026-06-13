// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title  UniversalOracle
 * @notice Multi-feed price + match-outcome oracle (quorum-based).
 *
 * Roles: DEFAULT_ADMIN_ROLE | ORACLE_ROLE (validators)
 */
contract UniversalOracle is AccessControl, Pausable {
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");

    uint8 public quorum = 2;

    enum Outcome { UNKNOWN, HOME, DRAW, AWAY }

    struct PriceFeed   { uint256 price; uint256 updatedAt; uint16 round; }
    struct MatchResult { Outcome outcome; uint256 settledAt; uint8 votes; bool finalized; }

    mapping(bytes32 => PriceFeed)                   public priceFeeds;
    mapping(bytes32 => MatchResult)                 public matchResults;
    mapping(bytes32 => mapping(address => Outcome)) private _votes;
    mapping(bytes32 => mapping(uint8   => uint8))   private _tally;

    event PriceFeedUpdated  (bytes32 indexed feedId,  uint256 price, uint256 ts);
    event MatchVoteSubmitted(bytes32 indexed matchId, address oracle, Outcome outcome);
    event MatchFinalized    (bytes32 indexed matchId, Outcome outcome, uint256 ts);
    event QuorumUpdated(uint8 prev, uint8 next);

    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ORACLE_ROLE, admin);
    }

    function submitPrice(bytes32 feedId, uint256 price) external onlyRole(ORACLE_ROLE) whenNotPaused {
        priceFeeds[feedId] = PriceFeed({ price: price, updatedAt: block.timestamp, round: priceFeeds[feedId].round + 1 });
        emit PriceFeedUpdated(feedId, price, block.timestamp);
    }

    function getPrice(bytes32 feedId) external view returns (uint256 price, uint256 updatedAt) {
        PriceFeed storage f = priceFeeds[feedId];
        require(f.updatedAt > 0, "Oracle: feed not found");
        require(block.timestamp - f.updatedAt <= 3600, "Oracle: stale");
        return (f.price, f.updatedAt);
    }

    function submitMatchOutcome(bytes32 matchId, Outcome outcome) external onlyRole(ORACLE_ROLE) whenNotPaused {
        require(outcome != Outcome.UNKNOWN, "Oracle: invalid outcome");
        MatchResult storage mr = matchResults[matchId];
        require(!mr.finalized && _votes[matchId][msg.sender] == Outcome.UNKNOWN, "Oracle: invalid state");
        _votes[matchId][msg.sender] = outcome;
        _tally[matchId][uint8(outcome)] += 1;
        mr.votes += 1;
        emit MatchVoteSubmitted(matchId, msg.sender, outcome);
        for (uint8 o = 1; o <= 3; o++) {
            if (_tally[matchId][o] >= quorum) {
                mr.outcome = Outcome(o); mr.settledAt = block.timestamp; mr.finalized = true;
                emit MatchFinalized(matchId, Outcome(o), block.timestamp);
                break;
            }
        }
    }

    function getMatchOutcome(bytes32 matchId) external view returns (Outcome outcome, bool finalized, uint256 settledAt) {
        MatchResult storage mr = matchResults[matchId];
        return (mr.outcome, mr.finalized, mr.settledAt);
    }

    function setQuorum(uint8 _q) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_q >= 1, "Oracle: quorum >= 1");
        emit QuorumUpdated(quorum, _q); quorum = _q;
    }
    function pause()   external onlyRole(DEFAULT_ADMIN_ROLE) { _pause(); }
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) { _unpause(); }
}
