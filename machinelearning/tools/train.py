def train(batch_size, model, device, train_loader, optimizer, epoch, loss_func):
    for batch_idx, (data, target) in enumerate(train_loader):
        data, target = data.to(device), target.to(device)
        optimizer.zero_grad()  # 清除所有优化的梯度
        output = model(data)
        loss = loss_func(output, target).sum()
        loss.backward()
        optimizer.step()
        if batch_idx % batch_size == 0:
            print('Train Epoch: {} [{}/{} ({:.0f}%)]\tLoss: {:.6f}'.format(
                epoch, batch_idx * len(data), len(train_loader.dataset),
                100. * batch_idx / len(train_loader), loss.item()))
