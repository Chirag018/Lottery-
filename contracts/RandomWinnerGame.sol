//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract RandomWinnerGame is VRFConsumerBase, Ownable {
    uint256 public fee;
    bytes32 public keyHash;
    address[] public players;
    uint8 maxPlayers;
    bool public gameStarted;
    uint256 entryFee;
    uint256 public gameId;

    event GameStarted(uint256 gameId, uint8 maxPlayers, uint256 entryFee);
    // emitted when someone joins a game
    event PlayerJoined(uint256 gameId, address player);
    // emitted when the game ends
    event GameEnded(uint256 gameId, address winner, bytes32 requestId);

    constructor(
        address vrfCoordinator,
        address linkToken,
        bytes32 vrfKeyHash,
        uint256 vrfFee
    ) VRFConsumerBase(vrfCoordinator, linkToken) {
        keyHash = vrfKeyHash;
        fee = vrfFee;
        gameStarted = false;
    }

    function startGame(uint8 _maxPlayer,uint256 _entryFee) public onlyOwner{
require(!gameStarted,'Game is running!!');
delete players;
maxPlayers=_maxPlayer;
gameStarted=true;
entryFee=_entryFee;
gameId+=1;
emit GameStarted(gameId, maxPlayers, entryFee);
    }

    function joinGame() public payable{
require(gameStarted,'Game has to began');
require(msg.value==entryFee,'Value sent is not equal to entryfee');
require(players.length<maxPlayers,'gameis full');
players.push(msg.sender);
if(players.length==maxPlayers) getRandomWinner();
    }

    function fulfillRandomness(bytes32 requestId,uint256 randomness) internal virtual(){
       uint256 winnerIndex=randomness%players.length;
       address winner=players[winnerIndex];
       (bool sent,)=winner.call{value:address(this).balance}('');
       require(sent,'failded to send ether);
  emit GameEnded(gameId,winner,requestId);
  gameStarted=false;
    }

    function getRandomWinner() private returns(bytes32 requestId){
require(LINK.balanceOf(address(this))>=fee,'Not enough');
return reqestRandomness(keyHash,fee);
    }
    receive() external payable{}

    fallback() external payable{}
}
