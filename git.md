# Git

同步仓库
```bash
# clone 老仓库，同步所有远程分支到本地
git clone --mirror <old url>

# 添加新remote地址
git remote add upstream <new url>

# 将本地所有分支同步到新远程地址
git push --mirror upstream
```

```bash
# 该命令会同步远程仓库的最新分支信息，并自动删除本地已失效的远程分支引用
git fetch --prune

# 清理特定远程仓库（如 upstream）的分支引用
git remote prune upstream

# 自动查找所有关联远程分支已删除的本地分支，并删除
git branch -vv | grep 'origin/.*: gone]' | awk '{print $1}' | xargs git branch -d

# 添加新remote地址，起名为upstream
git remote add upstream <新仓库URL>
```