FROM alpine:3 as downloader

ARG TARGETOS
ARG TARGETARCH
ARG TARGETVARIANT
ARG VERSION=0.20.7

ENV BUILDX_ARCH="${TARGETOS:-linux}_${TARGETARCH:-amd64}${TARGETVARIANT}"

RUN wget https://github.com/pocketbase/pocketbase/releases/download/v${VERSION}/pocketbase_${VERSION}_${BUILDX_ARCH}.zip \
    && unzip pocketbase_${VERSION}_${BUILDX_ARCH}.zip \
    && chmod +x /pocketbase

FROM node:21 as builder

WORKDIR /app

RUN git clone https://github.com/pocketbase/pocketbase .
COPY 0001-fix-apply-header-name-fix.patch .
RUN git apply 0001-fix-apply-header-name-fix.patch
RUN npm --prefix=./ui install && npm --prefix=./ui run build

FROM alpine:3
RUN apk update && apk add ca-certificates && rm -rf /var/cache/apk/*
RUN mkdir /pb_hooks

EXPOSE 8090

COPY --from=downloader /pocketbase /usr/local/bin/pocketbase
COPY --from=builder /app/ui/dist /pb_admin
COPY main.pb.js /pb_hooks/

ENTRYPOINT ["/usr/local/bin/pocketbase", "serve", "--http=0.0.0.0:8090", "--dir=/pb_data", "--publicDir=/pb_public", "--hooksDir=/pb_hooks"]
