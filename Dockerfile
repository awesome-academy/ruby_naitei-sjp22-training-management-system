FROM ruby:3.2.2

# Set timezone để tránh lỗi timezone data source
ENV TZ=Asia/Ho_Chi_Minh

# Cài đặt các package cần thiết bao gồm tzdata
RUN apt-get update -qq && apt-get install -y \
    build-essential \
    libpq-dev \
    nodejs \
    default-mysql-client \
    yarn \
    tzdata \
    dos2unix \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy Gemfile trước để tận dụng Docker layer caching
COPY Gemfile Gemfile.lock ./

# Install gems
RUN bundle install

# Copy toàn bộ source code
COPY . .

# Fix line endings cho tất cả các file quan trọng
RUN find . -type f \( -name "*.rb" -o -name "*.yml" -o -name "*.yaml" -o -name "*.sh" \) -exec dos2unix {} \; && \
    find ./bin -type f -exec dos2unix {} \; && \
    find ./bin -type f -exec chmod +x {} \; && \
    find . -name "rails" -type f -exec dos2unix {} \; && \
    find . -name "rake" -type f -exec dos2unix {} \; && \
    find . -name "bundle" -type f -exec dos2unix {} \;

# Fix quyền thực thi cho bin directory
RUN chmod -R +x ./bin

# Expose port
EXPOSE 3000

# Default command với đường dẫn đầy đủ
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0", "-p", "3000"]
