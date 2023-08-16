// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Exchange is ERC20 {
  // Future code goes here
  address public tokenAddress;

  constructor(address token) ERC20("ETH TOKEN LPToken", "LpEthtoken") {
    require(token != address(0), "Token address passed is a null address");
    token = tokenAddress;
  }

  function addLiquidity(uint256 amountOfToken) public payable returns (uint256) {
    uint256 lpTokenToMint;
    uint256 ethReserve = address(this).balance;
    uint256 tokenReserve = getReserve();
    ERC20 token = ERC20(tokenAddress);

    if (tokenReserve == 0) {
      token.transferFrom(msg.sender, address(this), amountOfToken);
      lpTokenToMint = ethReserve;
      _mint(msg.sender, lpTokenToMint);
      return lpTokenToMint;
    }

    uint256 ethReserveBeforeFuncCall = ethReserve - msg.value;
    uint256 minTokenReqd = (msg.value * tokenReserve) / ethReserveBeforeFuncCall;
    require(amountOfToken >= minTokenReqd, "Insufficient amount of tokens provided");

    token.transferFrom(msg.sender, address(this), minTokenReqd);

    lpTokenToMint = (totalSupply() * msg.value) / ethReserveBeforeFuncCall;

    // Mint LP tokens to the user
    _mint(msg.sender, lpTokenToMint);

    return lpTokenToMint;
  }

  function removeLiquidity(uint256 amountOfLpTokens) public returns (uint256, uint256) {
    require(amountOfLpTokens > 0, "amountOfLpTokens must be a positive number");

    uint256 ethReserve = address(this).balance;
    uint256 lpTokenReserve = totalSupply();

    uint256 ethToReturn = (ethReserve * amountOfLpTokens) / lpTokenReserve;
    uint256 tokenToReturn = (getReserve() * amountOfLpTokens) / lpTokenReserve;

    _burn(msg.sender, amountOfLpTokens);
    payable(msg.sender).transfer(ethToReturn);
    ERC20(tokenAddress).transfer(msg.sender, tokenToReturn);
    return (ethToReturn, tokenToReturn);
  }

  function getOutputAmountFromSwap(
    uint256 inputamount,
    uint256 inputreserve,
    uint256 outputreserve
  ) public pure returns (uint256) {
    require(inputreserve > 0 && outputreserve > 0, "Reserves must be greater than zero");
    uint256 inputAfterFee = 99 * inputamount;
    uint256 numerator = inputAfterFee * outputreserve;
    uint256 denominator = inputAfterFee + inputreserve * 100;

    return numerator / denominator;
  }

  function ethToTokenSwap(uint256 minTokensToReceive) public payable {
    uint256 tokenReserveBalance = getReserve();
    uint256 tokensToReceive = getOutputAmountFromSwap(
      msg.value,
      address(this).balance - msg.value,
      tokenReserveBalance
    );

    require(
      tokensToReceive >= minTokensToReceive,
      "Tokens received are less than minimum tokens expected"
    );

    ERC20(tokenAddress).transfer(msg.sender, tokensToReceive);
  }

  // tokenToEthSwap allows users to swap tokens for ETH

  function tokenToEthSwap(uint256 tokensToSwap, uint256 minEthToReceive) public {
    uint256 tokenReserveBalance = getReserve();
    uint256 ethToReceive = getOutputAmountFromSwap(
      tokensToSwap,
      tokenReserveBalance,
      address(this).balance
    );

    require(
      ethToReceive >= minEthToReceive,
      "ETH received is less than minimum ETH expected"
    );

    ERC20(tokenAddress).transferFrom(msg.sender, address(this), tokensToSwap);

    payable(msg.sender).transfer(ethToReceive);
  }

  function getReserve() public view returns (uint256) {
    // amount on token on this contract
    return ERC20(tokenAddress).balanceOf(address(this));
  }
}
