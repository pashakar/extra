const { expect } = require("chai");
const { ethers } = require("hardhat");
const { time } = require("@nomicfoundation/hardhat-network-helpers");

const [percentsFor3Minutes, percentsFor5Minutes, percentsFor10Minutes] = [
  1000, 2000, 3000,
];
const procents = 10000;

describe("Staking unit tests", () => {
  before(async () => {
    [this.owner, this.user] = await ethers.getSigners();
    this.staking = await (
      await ethers.getContractFactory("Staking")
    ).deploy(percentsFor3Minutes, percentsFor5Minutes, percentsFor10Minutes);
  });

  it("should check owner of contract", async () => {
    expect(await this.staking.owner()).to.equal(this.owner.address);
  });

  it("should to check create deposit", async () => {
    const stakingAmount = ethers.utils.parseEther("1");
    const invalidAmount = 0;

    const duration = 3;
    await expect(
      this.staking.connect(this.user).createDeposit(duration, {
        value: stakingAmount,
      })
    )
      .to.emit(this.staking, "DepositCreate")
      .withArgs(this.user.address, stakingAmount, duration);

    expect(await this.staking.allBalanceStaking()).to.equal(stakingAmount);

    await expect(
      this.staking.connect(this.user).createDeposit(duration, {
        value: invalidAmount,
      })
    ).to.be.rejectedWith("!amount");

    await expect(
      this.staking.connect(this.user).createDeposit(duration, {
        value: stakingAmount,
      })
    ).to.changeEtherBalance(this.staking, stakingAmount);
  });

  it("should to check withdraw deposit", async () => {
    const stakingAmount = ethers.utils.parseEther("1");
    const duration = 3;

    await expect(
      this.staking.connect(this.user).createDeposit(duration, {
        value: stakingAmount,
      })
    ).to.changeEtherBalance(this.staking, stakingAmount);

    const rewardsAmount = stakingAmount
      .mul(percentsFor3Minutes)
      .div(procents)
      .add(stakingAmount);

    const timeWithdraw = (await time.latest()) + duration * 60;
    await time.increaseTo(timeWithdraw);

    await expect(
      this.staking.connect(this.user).withdrawDeposit()
    ).to.changeEtherBalance(this.user, rewardsAmount);

    expect(
      await this.staking.connect(this.user).createDeposit(duration, {
        value: stakingAmount,
      })
    ).to.not.be.reverted;

    await expect(
      this.staking.connect(this.user).withdrawDeposit()
    ).to.be.revertedWith("!period");
  });

  it("should to check set params", async () => {
    const [minutes, stakingReward] = [20, 1];
    expect(await this.staking.setParams(minutes, stakingReward)).to.not.be
      .reverted;

    await expect(
      this.staking.connect(this.user).setParams(minutes, stakingReward)
    ).to.be.revertedWith("!owner");
  });

  it("should to check get info about deposit", async () => {
    const newUser = (await ethers.getSigners())[2];
    const stakingAmount = ethers.utils.parseEther("1");
    const duration = 3;

    await expect(
      this.staking.connect(newUser).createDeposit(duration, {
        value: stakingAmount,
      })
    ).to.not.be.reverted;

    const [addr, startTime, endTime] = await this.staking.getDepositInfo(
      newUser.address
    );
    expect(addr).to.equal(newUser.address);
    expect(startTime).to.equal(await time.latest());
    expect(endTime).to.equal((await time.latest()) + duration * 60);
  });
});
