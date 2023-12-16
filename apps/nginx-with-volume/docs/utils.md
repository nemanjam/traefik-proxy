```bash
git remote add gitlab git@gitlab.com:nemanjam/nginx-with-volume.git && \
git remote add all git@github.com:nemanjam/nginx-with-volume.git && \
git remote set-url --add --push all git@github.com:nemanjam/nginx-with-volume.git && \
git remote set-url --add --push all git@gitlab.com:nemanjam/nginx-with-volume.git && \
git remote -v
```
