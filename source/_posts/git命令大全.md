---
title: git命令大全
categories:
  - 工具
  - Git
tags:
  - Git命令
comments: true
toc: true
date: 2018-02-26 13:49:56
---
### 查看、添加、提交、删除、找回，重置修改文件
    git help <command> # 显示command的help
    git show # 显示某次提交的内容 git show $id
    git checkout -- <file> # 抛弃工作区修改
    git checkout . # 抛弃工作区修改
    git add <file> # 将工作文件修改提交到本地暂存区
    git add . # 将所有修改过的工作文件提交暂存区
    git rm <file> # 从版本库中删除文件
    git rm <file> --cached # 从版本库中删除文件，但不删除文件
    git reset <file> # 从暂存区恢复到工作文件
    git reset -- . # 从暂存区恢复到工作文件
    git reset --hard # 恢复最近一次提交过的状态，即放弃上次提交后的所有本次修改
    git commit <file> 
    git commit . 
    git commit -a # 将git add, git rm和git ci等操作都合并在一起做　　
    git commit -am "some comments"
    git commit --amend # 修改最后一次提交记录
    git revert <$id> # 恢复某次提交的状态，恢复动作本身也创建次提交对象
    git revert HEAD # 恢复最后一次提交的状态

### 查看文件diff
    git diff <file> # 比较当前文件和暂存区文件差异 git diff
    git diff <id1><id1><id2> # 比较两次提交之间的差异
    git diff <branch1>..<branch2> # 在两个分支之间比较
    git diff --staged # 比较暂存区和版本库差异
    git diff --cached # 比较暂存区和版本库差异
    git diff --stat # 仅仅比较统计信息

### 查看提交记录
    git log  # 查看分支的提交记录
    git log <file> # 查看该文件每次提交记录
    git log -p <file> # 查看每次详细修改内容的diff
    git log -p -2 # 查看最近两次详细修改内容的diff
    git log --stat #查看提交统计信息

### 查看、切换、创建和删除分支
    git branch -r # 查看远程分支
    git branch <new_branch> # 创建新的分支
    git branch -v # 查看各个分支最后提交信息
    git branch --merged # 查看已经被合并到当前分支的分支
    git branch --no-merged # 查看尚未被合并到当前分支的分支
    git checkout <branch> # 切换到某个分支
    git checkout -b <new_branch> # 创建新的分支，并且切换过去
    git checkout -b <new_branch> <branch> # 基于branch创建新的new_branch
    git checkout $id # 把某次历史提交记录checkout出来，但无分支信息，切换到其他分支会自动删除
    git checkout $id -b <new_branch> # 把某次历史提交记录checkout出来，创建成一个分支
    git branch -d <branch> # 删除某个分支
    git branch -D <branch> # 强制删除某个分支 (未被合并的分支被删除的时候需要强制)
### 分支合并和rebase
    git merge <branch> # 将branch分支合并到当前分支
    git merge origin/master --no-ff # 不要Fast-Foward合并，这样可以生成merge提交
    git rebase master <branch> # 将master rebase到branch，相当于： git co <branch> && git rebase master && git co master && git merge <branch>
### 同步远程分支目录到本地
    git remote update origin --prune


### Git补丁管理(方便在多台机器上开发同步时用)

    git diff > ../sync.patch # 生成补丁
    
    git apply ../sync.patch # 打补丁
    
    git apply --check ../sync.patch #测试补丁能否成功

### Git暂存管理

    git stash # 暂存
    
    git stash list # 列所有stash
    
    git stash apply # 恢复暂存的内容
    
    git stash drop # 删除暂存区

### Git远程分支管理

    git pull # 抓取远程仓库所有分支更新并合并到本地
    
    git pull --no-ff # 抓取远程仓库所有分支更新并合并到本地，不要快进合并
    
    git fetch origin # 抓取远程仓库更新
    
    git merge origin/master # 将远程主分支合并到本地当前分支
    
    git checkout --track origin/branch # 跟踪某个远程分支创建相应的本地分支
    
    git checkout -b <local_branch> origin/<remote_branch> # 基于远程分支创建本地分支，功能同上
    
    git push # push所有分支
    
    git push origin master # 将本地主分支推到远程主分支
    
    git push -u origin master # 将本地主分支推到远程(如无远程主分支则创建，用于初始化远程仓库)
    
    git push origin <local_branch> # 创建远程分支， origin是远程仓库名
    
    git push origin <local_branch>:<remote_branch> # 创建远程分支
    
    git push origin :<remote_branch> #先删除本地分支(git br -d <branch>)，然后再push删除远程分支

### Git远程仓库管理

    git remote -v # 查看远程服务器地址和仓库名称
    
    git remote show origin # 查看远程服务器仓库状态
    
    git remote add origin git@ github:robbin/robbin_site.git # 添加远程仓库地址
    
    git remote set-url origin git@ github.com:robbin/robbin_site.git # 设置远程仓库地址(用于修改远程仓库地址) git remote rm <repository> # 删除远程仓库

### 创建远程仓库

    git clone --bare robbin_site robbin_site.git # 用带版本的项目创建纯版本仓库
    
        scp -r my_project.git git@ git.csdn.net:~ # 将纯仓库上传到服务器上
        
        mkdir robbin_site.git && cd robbin_site.git && git --bare init # 在服务器创建纯仓库
    
    git remote add origin git@ github.com:robbin/robbin_site.git # 设置远程仓库地址
    
    git push -u origin master # 客户端首次提交
    
    git push -u origin develop # 首次将本地develop分支提交到远程develop分支，并且track
    
    git remote set-head origin master # 设置远程仓库的HEAD指向master分支
    
    也可以命令设置跟踪远程库和本地库
    
    git branch --set-upstream master origin/master
    
    git branch --set-upstream develop origin/develop

### git init
    在本地新建一个repo,进入一个项目目录,执行git init,会初始化一个repo,并在当前文件夹下创建一个.git文件夹.

### git clone
    获取一个url对应的远程Git repo, 创建一个local copy.
    一般的格式是git clone [url].
    clone下来的repo会以url最后一个斜线后面的名称命名,创建一个文件夹,如果想要指定特定的名称,可以git clone [url] newname指定.

### git status
    查询repo的状态.
    git status -s: -s表示short, -s的输出标记会有两列,第一列是对staging区域而言,第二列是对working目录而言.

### git log
    在当前分支上查看提交日志
    git log --oneline --number: 每条log只显示一行,显示number条.
    
    git log --oneline --graph:可以图形化地表示出分支合并历史.
    
    git log branchname可以显示特定分支的log.
    
    git log --oneline branch1 ^branch2,可以查看在分支1,却不在分支2中的提交.^表示排除这个分支(Window下可能要给^branch2加上引号).
    
    git log --decorate会显示出tag信息.
    
    git log --author=[author name] 可以指定作者的提交历史.
    
    git log --since --before --until --after 根据提交时间筛选log.
    --no-merges可以将merge的commits排除在外.
    
    git log --grep 根据commit信息过滤log: git log --grep=keywords
    默认情况下, git log --grep --author是OR的关系,即满足一条即被返回,如果你想让它们是AND的关系,可以加上--all-match的option.
    
    git log -S: filter by introduced diff.
    比如: git log -SmethodName (注意S和后面的词之间没有等号分隔).
    
    git log -p: show patch introduced at each commit.
    每一个提交都是一个快照(snapshot),Git会把每次提交的diff计算出来,作为一个patch显示给你看.
    另一种方法是git show [SHA].
    
    git log --stat: show diffstat of changes introduced at each commit.
    同样是用来看改动的相对信息的,--stat比-p的输出更简单一些.


### git commit
    提交已经被add进来的改动.
    git commit -m “the commit message"
    
    git commit -a 会先把所有已经track的文件的改动add进来,然后提交(有点像svn的一次提交,不用先暂存). 对于没有track的文件,还是需要git add一下.
    
    git commit --amend 增补提交. 会使用与当前提交节点相同的父节点进行一次新的提交,旧的提交将会被取消.

### git reset
     undo changes and commits.
     这里的HEAD关键字指的是当前分支最末梢最新的一个提交.也就是版本库中该分支上的最新版本.
     git reset HEAD: unstage files from index and reset pointer to HEAD
     这个命令用来把不小心add进去的文件从staged状态取出来,可以单独针对某一个文件操作: git reset HEAD - - filename, 这个- - 也可以不加.
     git reset --soft
     move HEAD to specific commit reference, index and staging are untouched.
     git reset --hard
     unstage files AND undo any changes in the working directory since last commit.
     使用git reset —hard HEAD进行reset,即上次提交之后,所有staged的改动和工作目录的改动都会消失,还原到上次提交的状态.
     这里的HEAD可以被写成任何一次提交的SHA-1.
     不带soft和hard参数的git reset,实际上带的是默认参数mixed.
 
     总结:
     git reset --mixed id,是将git的HEAD变了(也就是提交记录变了),但文件并没有改变，(也就是working tree并没有改变). 取消了commit和add的内容.
     git reset --soft id. 实际上，是git reset –mixed id 后,又做了一次git add.即取消了commit的内容.
     git reset --hard id.是将git的HEAD变了,文件也变了.
     按改动范围排序如下:
     soft (commit) < mixed (commit + add) < hard (commit + add + local working)
     
### git revert
     反转撤销提交.只要把出错的提交(commit)的名字(reference)作为参数传给命令就可以了.
     git revert HEAD: 撤销最近的一个提交.
     git revert会创建一个反向的新提交,可以通过参数-n来告诉Git先不要提交.

### git rm
     git rm file: 从staging区移除文件,同时也移除出工作目录.
     git rm --cached: 从staging区移除文件,但留在工作目录中.
     git rm --cached从功能上等同于git reset HEAD,清除了缓存区,但不动工作目录树.

### git clean
     git clean是从工作目录中移除没有track的文件.
     通常的参数是git clean -df:
     -d表示同时移除目录,-f表示force,因为在git的配置文件中, clean.requireForce=true,如果不加-f,clean将会拒绝执行.

### git rebase
     --rebase不会产生合并的提交,它会将本地的所有提交临时保存为补丁(patch),放在”.git/rebase”目录中,然后将当前分支更新到最新的分支尖端,最后把保存的补丁应用到分支上.
     rebase的过程中,也许会出现冲突,Git会停止rebase并让你解决冲突,在解决完冲突之后,用git add去更新这些内容,然后无需执行commit,只需要:
     git rebase --continue就会继续打余下的补丁.
     git rebase --abort将会终止rebase,当前分支将会回到rebase之前的状态.

### git reflog
     git reflog是对reflog进行管理的命令,reflog是git用来记录引用变化的一种机制,比如记录分支的变化或者是HEAD引用的变化.
     当git reflog不指定引用的时候,默认列出HEAD的reflog.
     HEAD@{0}代表HEAD当前的值,HEAD@{3}代表HEAD在3次变化之前的值.
     git会将变化记录到HEAD对应的reflog文件中,其路径为.git/logs/HEAD, 分支的reflog文件都放在.git/logs/refs目录下的子目录中.
     
### cherry-pick
    它会获取某一个分支的单笔提交，并作为一个新的提交引入到你当前分支上
    git cherry-pick [<options>] <commit-ish>...
    常用options:
        --quit                退出当前的chery-pick序列
        --continue            继续当前的chery-pick序列
        --abort               取消当前的chery-pick序列，恢复当前分支
        -n, --no-commit       不自动提交
        -e, --edit            编辑提交信息
